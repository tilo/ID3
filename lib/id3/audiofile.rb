# ==============================================================================
# Class AudioFile    may call this ID3File
#
#    reads and parses audio files for tags
#    writes audio files and attaches dumped tags to it..
#    revert feature would be nice to have..
# 
#    If we query and AudioFile object, we query what's currently associated with it
#    e.g. we're not querying the file itself, but the Tag object which is perhaps modified.
#    To query the file itself, use the ID3 module functions
#
#    By default the audio portion of the file is not(!) read - to reduce memory footprint - the audioportion could be very long!
#
# BUG: (1) : when a id3v2 frame is deleted from a tag, e.g. 'PICTURE', then the raw tag is not updated
# BUG: (2) : when a AudioFile is written to file, the raw tag is not updated to reflect the new raw tag value
# BUG: (3) : FIXED. when a AufioFile is written, the order of frames is not the same as in the original file.. fixed using OrderedHash
# BUG: (5) : when a FrameType is set for a ID3v2 tag, e.g. 'TITLE', the underlying attributes are not automatically pre-filled..

class AudioFile
  attr_reader :audioStartX , :audioEndX     # begin and end indices of audio data in file
  
  attr_reader :pwd,          :filename      # PWD and relative path/name how file was first referenced
  attr_reader :dirname,      :basename      # absolute dirname and basename of the file (computed)
  
  attr_accessor :tagID3v1, :tagID3v2    # should make aliases id3v1_tag , id3v2_tag 
  
  # ----------------------------------------------------------------------------
  # initialize
  #
  #   AudioFile.new   does NOT keep the file open, but scans it and parses the info
  #   e.g.:  ID3::AudioFile.new('mp3/a.mp3')

  # this should take two parameters, either Filename or String, and an options hash, e.g. {:read_audio => false}

  def initialize( filename )
    @filename     = filename      # similar to path method from class File, which is a mis-nomer!
    @pwd          = ENV["PWD"]
    @dirname      = File.dirname( filename )
    @basename     = File.basename( filename )
    
    @tagID3v1     = nil
    @tagID3v2     = nil

    @audio        = nil           # this doesn't get initialized with the actual audio during new(), so we don't waste memory

    audioStartX   = 0
    audioEndX     = File.size(filename) - 1  # points to the last index

    if ID3.hasID3v1tag?(@filename)
      @tagID3v1 = ID3::Tag1.new
      @tagID3v1.read(@filename)

      audioEndX -= ID3::ID3v1tagSize
    end
    if ID3.hasID3v2tag?(@filename) 
      @tagID3v2 = ID3::Tag2.new
      @tagID3v2.read(@filename)

      audioStartX = @tagID3v2.raw.size
    end
    
    # audioStartX audioEndX indices into the file need to be set
    @audioStartX = audioStartX     # first byte of audio data
    @audioEndX   = audioEndX       # last byte of audio data
    
    # user may compute the MD5sum of the audio content later..
    # but we're only doing this if the user requests it..
    # because MD5sum computation takes a little bit time.

    @audioMD5sum = nil
    @audioSHA1sum = nil
  end

  # ----------------------------------------------------------------------------
  # version    aka    versions
  #     queries the tag objects and returns the version numbers of those tags
  #     NOTE: this does not reflect what's currently in the file, but what's
  #           currently in the AudioFile object
  
  def id3_versions       # returns Array of ID3 tag versions found
    a = Array.new
    a.push(@tagID3v1.version) if @tagID3v1
    a.push(@tagID3v2.version) if @tagID3v2
    return a
  end
  alias versions id3_versions
  alias version  id3_versions
  # ----------------------------------------------------------------------------
  def has_id3v1tag?
    return @tagID3v1
  end
  # ----------------------------------------------------------------------------
  def has_id3v2tag?
    return @tagID3v2
  end
  # ----------------------------------------------------------------------------
  def audioLength
    @audioEndX - @audioStartX + 1
  end
  # ----------------------------------------------------------------------------
  # write
  #     write the AudioFile to file, including any ID3-tags
  #     We keep backups if we write to a specific filename
  
  def write(*filename)
    backups = false
    
    if filename.size == 0     # this is an Array!!
      filename = @filename
      backups  = true        # keep backups if we write to a specific filename
    else
      filename = filename[0]
      backups = false
    end
    
    tf = Tempfile.new( @basename )
    tmpname = tf.path
    
    # write ID3v2 tag:
    
    if @tagID3v2
      tf.write( @tagID3v2.dump )
    end
    
    # write Audio Data:
    
    tf.write( audio ) # reads audio from file if nil
    
    # write ID3v1 tag:
    
    if @tagID3v1
      tf.write( @tagID3v1.dump )
    end
    
    tf.close
    
    # now some logic about moving the tempfile and replacing the original

    bakname = filename + '.bak'
    move(filename, bakname) if backups && FileTest.exists?(filename) && ! FileTest.exists?(bakname)

    move(tmpname, filename)
    tf.close(true)
    
    # write md5sum sha1sum files:
    writeMD5sum if @audioMD5sum
    writeSHA1sum if @audioSHA1sum
  end
  
  # ----------------------------------------------------------------------------
  # readAudion
  #     read audio into @audio buffer either from String or from File
  def audio
    @audio ||= readAudio    # read the audio portion of the file only once, the first time this is called.
  end

  def readAudio
    File.open( File.join(@dirname, @basename) ) do |f|
      f.seek(@audioStartX)
      f.read(@audioEndX - @audioStartX + 1) 
    end
  end
  # ----------------------------------------------------------------------------
  # writeAudio
  #     only for debugging, does not write any ID3-tags, but just the audio portion
  
  def writeAudioOnly
    tf = Tempfile.new( @basename )
    
    File.open( @filename ) { |f|
      f.seek(@audioStartX)
      tf.write( audio )   # reads the audio from file if nil
    }
    tf.close
    path = tf.path
    
    tf.open
    tf.close(true)
  end
  
  
  # ----------------------------------------------------------------------------
  # NOTE on md5sum's:
  #    If you don't know what an md5sum is, you can think of it as a unique 
  #    fingerprint of a file or some data.  I added the md5sum computation to
  #    help users keep track of their converted songs - even if the ID3-tag of
  #    a file changes(!), the md5sum of the audio data does not change..
  #    The md5sum can help you ensure that the audio-portion of the file
  #    was not changed after modifying, adding or deleting ID3-tags.
  #    It can also help you identifying duplicates.
  
  # ----------------------------------------------------------------------------
  # audioMD5sum
  #     if the user tries to access @audioMD5sum, it will be computed for him, 
  #     unless it was previously computed. We try to calculate that only once 
  #     and on demand, because it's a bit expensive to compute..
  
  def audioMD5sum
    @audioMD5sum ||= MD5.hexdigest( audio )
  end

  def audioSHA1sum
    @audioSHA1sum ||= SHA1.hexdigest( audio )
  end
  # ----------------------------------------------------------------------------
  # writeMD5sum
  #     write the filename and MD5sum of the audio portion into an ascii file 
  #     in the same location as the audio file, but with suffix .md5
  #
  #     computes the @audioMD5sum, if it wasn't previously computed..

  def writeMD5sum
    base = @basename.sub( /(.)\.[^.]+$/ , '\1')
    base += '.md5'
    File.open( File.join(@dirname,base) ,"w") { |f| 
      f.printf("%s   %s\n",  File.join(@dirname,@basename), audioMD5sum ) # computes it if nil
    }
    @audioMD5sum
  end

  def writeSHA1sum
    base = @basename.sub( /(.)\.[^.]+$/ , '\1')
    base += '.sha1'
    File.open( File.join(@dirname,base) ,"w") { |f| 
      f.printf("%s   %s\n",  File.join(@dirname,@basename), audioSHA1sum ) # computes it if nil
    }
    @audioSHA1sum
  end
  # ----------------------------------------------------------------------------
  # verifyMD5sum
  #     compare the audioMD5sum against a previously stored md5sum file
  #     and returns boolean value of comparison
  #
  #     If no md5sum file existed, we create one and return true.
  #
  #     computes the @audioMD5sum, if it wasn't previously computed..

  def verifyMD5sum

    oldMD5sum = ''
    
    self.audioMD5sum if ! @audioMD5sum  # compute MD5sum if it's not computed yet

    base = @basename.sub( /(.)\.[^.]+$/ , '\1')   # remove suffix from audio-file
    base += '.md5'                                # add new suffix .md5
    md5name = File.join(@dirname,base)
    
    # if a MD5-file doesn't exist, we should create one and return TRUE ...
    if File.exists?(md5name)
      File.open( md5name ,"r") { |f| 
        oldname,oldMD5sum = f.readline.split  # read old MD5-sum
      }
    else
      oldMD5sum = self.writeMD5sum        # create MD5-file and return true..
    end
    @audioMD5sum == oldMD5sum
    
  end
  # ----------------------------------------------------------------------------
  
end   # of class AudioFile
