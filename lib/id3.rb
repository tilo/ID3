################################################################################
# id3v2.rb     Ruby Module for handling the following ID3-tag versions:
#                  ID3v1.0 , ID3v1.1,  ID3v2.2.0, ID3v2.3.0, ID3v2.4.0
# 
# Copyright:   Tilo Sloboda <tilo@unixgods.org> , created 12 October 2002
#
# Docs:   http://www.id3.org/id3v2-00.txt
#         http://www.id3.org/id3v2.3.0.txt
#         http://www.id3.org/id3v2.4.0-changes.txt
#         http://www.id3.org/id3v2.4.0-structure.txt
#         http://www.id3.org/id3v2.4.0-frames.txt
#
# License:     
#         Freely available under the terms of the OpenSource "Artistic License"
#         in combination with the Addendum A (below)
# 
#         In case you did not get a copy of the license along with the software, 
#         it is also available at:   http://www.unixgods.org/~tilo/replace_string/ 
#
# Addendum A: 
#         THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU!
#         SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
#         REPAIR OR CORRECTION. 
#
#         IN NO EVENT WILL THE COPYRIGHT HOLDERS  BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, 
#         SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY 
#         TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED 
#         INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM 
#         TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF THE COPYRIGHT HOLDERS OR OTHER PARTY HAS BEEN
#         ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
#
#-------------------------------------------------------------------------------
#  Module ID3
#
#    n = ID3.hastag?(filename)
#
#    ID3.field[SYMBOLIC_FIELD] = "value";
#
#    ID3.update
#
#   Class ID3tag
#      @version          ID3 version
#      @size             size of the tag
#      @seek             position in bytes where to find the tag.
#
#   Class ID3v1tag       (formerly class Mp3Tag )
#
#      new(filename)     .. calls readtag
#      commit
#      removetag
#      filename
#      readtag
#
#      @songname             songname     songname=
#      @artist               artist       artist=
#      @album                album        album=
#      @year                 year         year=
#      @comment              comment      comment=
#      @tracknum             tracknum     tracknum=
#      @genre_id             genre_id     genre_id=
#      @genre                genre        genre=
#
#   Class ID3v2tag
#
#      
#
#
#
#   Class ID3v2frame
#
#      - each frame knows what it's name is, what the size is, how to read/write itself,
#        and how to input/output parameters from/to the user, knows how to compute it's size
#        
#
#         TextFrame < Frame
#         BinaryFrame < Frame
#
#
#
#   - ideally the user should be able to use a high-level interface to just 
#     read/write/update a tag, without knowing the gory details
#
#   - advanced users should be able to use a lower level interface to have more control
#
################################################################################



class String
  # ----------------------------------------------------------------------
  # prints out a good'ol hexdump of the data contained in the string

  def hexdump(verbose = 0)
     selfsize = self.size
     offset = 0
    
     chunks,rest = selfsize.divmod(16)
     address = offset; i = 0 
     print "\n address     0 1 2 3  4 5 6 7  8 9 A B  C D E F\n\n"
     while i < chunks*16
        str = self[i..i+15]
        if str != "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
          str.tr!("\000-\037\177-\377",'.')
          printf( "%08x    %8s %8s %8s %8s    %s\n", 
                address, self[i..i+3].unpack('H8'), self[i+4..i+7].unpack('H8'),
                   self[i+8..i+11].unpack('H8'), self[i+12..i+15].unpack('H8'),
		 str)
	else
          # we don't print lines with all zeroes
          if (verbose == 1)
             str.tr!("\000-\037\177-\377",'.')
             printf( "%08x    %8s %8s %8s %8s    %s\n", 
                address, self[i..i+3].unpack('H8'), self[i+4..i+7].unpack('H8'),
                   self[i+8..i+11].unpack('H8'), self[i+12..i+15].unpack('H8'),
		    str)
	  end
	end
        i += 16; address += 16
     end
     j = i; k = 0
     if (i < selfsize)
	printf( "%08x    ", address)
	while (i < selfsize)
	     printf "%02x", self[i]
	     i += 1; k += 1
	     print  " " if ((i % 4) == 0)
	end
	for i in (k..15)
	       print "  "
	end
	str = self[j..selfsize]
	str.tr!("\000-\037\177-\377",'.')
        printf ("     %s\n", str)
     end
  end

end


module ID3

  # check if file has a ID3-tag and which version it is
  # 
  # NOTE: file might be tagged twice! :(
  
  # ----------------------------------------------------------------------------
  #    CONSTANTS
  # ----------------------------------------------------------------------------
  ID3v1tagSize = 128;    # ID3v1 and ID3v1.1 have fixed size tags at end of file
  ID3v2headerSize = 10;

  # different versions of ID3 tags, support different fields.
  # See: http://www.unixgods.org/~tilo/ID3v2_frames_comparison.txt

  SUPPORTED_SYMBOLS = {
    "1.0"   => {"ARTIST"=>33..62 , "ALBUM"=>63..92 ,"TITLE"=>3..32,
                "YEAR"=>93..96 , "COMMENT"=>97..126,"GENREID"=>127
               }  ,
    "1.1"   => {"ARTIST"=>33..62 , "ALBUM"=>63..92 ,"TITLE"=>3..32,
                "YEAR"=>93..96 , "COMMENT"=>97..124,"TRACKNUM"=>126,
                "GENREID"=>127
               }  ,


    "2.2.0" => {"CONTENTGROUP"=>"TT1", "TITLE"=>"TT2", "SUBTITLE"=>"TT3",
                "ARTIST"=>"TP1", "BAND"=>"TP2", "CONDUCTOR"=>"TP3", "MIXARTIST"=>"TP4",
                "COMPOSER"=>"TCM", "LYRICIST"=>"TXT", "LANGUAGE"=>"TLA", "CONTENTTYPE"=>"TCO",
                "ALBUM"=>"TAL", "TRACKNUM"=>"TRK", "PARTINSET"=>"TPA", "ISRC"=>"TRC", 
                "DATE"=>"TDA", "YEAR"=>"TYE", "TIME"=>"TIM", "RECORDINGDATES"=>"TRD",
                "ORIGYEAR"=>"TOR", "BPM"=>"TBP", "MEDIATYPE"=>"TMT", "FILETYPE"=>"TFT", 
                "COPYRIGHT"=>"TCR", "PUBLISHER"=>"TPB", "ENCODEDBY"=>"TEN", 
                "ENCODERSETTINGS"=>"TSS", "SONGLEN"=>"TLE", "SIZE"=>"TSI",
                "PLAYLISTDELAY"=>"TDY", "INITIALKEY"=>"TKE", "ORIGALBUM"=>"TOT",
                "ORIGFILENAME"=>"TOF", "ORIGARTIST"=>"TOA", "ORIGLYRICIST"=>"TOL",
                "USERTEXT"=>"TXX", 
                "WWWAUDIOFILE"=>"WAF"
                #
                ### to be continued.. 
               } ,
    "2.3.0" => {},
    "2.4.0" => {}
  }
  # ----------------------------------------------------------------------------
  #    VARIABLES
  # ----------------------------------------------------------------------------
  
  # ----------------------------------------------------------------------------
  #    METHODS
  # ----------------------------------------------------------------------------

  # ----------------------------------------------------------------------------
  # has_v1_tag? 
  #              returns true if v1.0 or v1.1 tag was found 

  def ID3::has_v1_tag?(filename)
    hastag     = 0
    
    f = File.open(filename, 'r')
    f.seek(-ID3v1tagSize, IO::SEEK_END)
    if (f.read(3) == "TAG")
      f.seek(-ID3v1tagSize + 124, IO::SEEK_END)
      c = f.getc;                         # this is character 125 of the tag
  #   print "char = #{c}\n"
      if (c == 0) 
         hastag = "1.1"
      else
         hastag = "1.0"
      end
    end
    f.close
    return hastag
  end

  # ----------------------------------------------------------------------------
  # has_v2_tag? 
  #              returns true if a tag version 2.2.0, 2.3.0 or 2.4.0 was found 
  
  def ID3::has_v2_tag?(filename)
    hastag     = 0
    
    f = File.open(filename, 'r')
    if (f.read(3) == "ID3")
       major = f.getc
       minor = f.getc
       ver   = "2." + major.to_s + '.' + minor.to_s
       hastag = ver
    end
    f.close
    return hastag
  end


## -- Class ID3tag -------------------------------------------------------------

class ID3tag < Hash

  # ----------------------------------------------------------------------------
  #    VARIABLES
  # ----------------------------------------------------------------------------

  alias old_set []=

  def []=(key,val)
     if  SUPPORTED_SYMBOLS[@version].keys.include?(key)
        old_set(key,val)
     else 
        # exception
        raise ArgumentError, "Incorrect ID3-field \"#{key}\" for ID3 version #{@version}\n" +
                             "\t\tvalid fields are: " + SUPPORTED_SYMBOLS[@version].keys.join(",") +"\n"
     end
  end

  # keys, values, each, etc. come for free with Hash

  # ----------------------------------------------------------------------------
  #    PRIVATE METHODS
  # ----------------------------------------------------------------------------

  def initialize
 
      @version = ""
      @raw     = "";    # the raw ID3 tag
  end

  # ----------------------------------------------------------------------------
  # readN 
  #         read N bytes and interprets them as a base 256 number
  #
  def readNbytes(f, n)
    x = 0
    for i in 1..n
      x +=  256**(n-i)*f.read(1)[0]
    end
    return x
  end

  # ----------------------------------------------------------------------
  # convert the 4 bytes found in the id3v2 header and return the size

  def unmungeSize(bytes)
    size = 0
    j = 0; i = 3 
    while i >= 0
       size += 128**i * (bytes[j] & 0x7f)
       j += 1
       i -= 1
    end
    return size
  end
  # ----------------------------------------------------------------------
  # convert the size into 4 bytes to be written into an id3v2 header
  
  def mungeSize(size)
    bytes = Array.new(4,0)
    j = 0;  i = 3
    while i >= 0
      bytes[j],size = size.divmod(128**i)
      j += 1
      i -= 1
    end

    return bytes
  end

  # ----------------------------------------------------------------------------
  #    PUBLIC METHODS
  # ----------------------------------------------------------------------------


  # ----------------------------------------------------------------------
  # read_v1     reads a version 1.x ID3tag
  #
  #     30 title
  #     30 artist
  #     30 album
  #      4 year
  #     30 comment
  #      1 genre
  
  def read_v1(filename)
    f = File.open(filename, 'r')
    f.seek(-ID3::ID3v1tagSize, IO::SEEK_END)
    hastag = (f.read(3) == 'TAG')
    if hastag
      f.seek(-ID3::ID3v1tagSize, IO::SEEK_END)
      @raw = f.read(ID3::ID3v1tagSize)
      if (raw[125] == 0) 
         @version = "1.1"
      else
         @version = "1.0"
      end
    else
      @raw = @version = ""
    end
    f.close
    #
    # now parse all the fields

    ID3::SUPPORTED_SYMBOLS[@version].each{ |key,val|
       if val.type == Range
          @field[key] = @raw[val].squeeze(" \000").chomp(" ").chomp("\000")
       elsif val.type == Fixnum
          @field[key] = @raw[val].to_s
       else 
          printf "unknown key/val : #{key} / #{val}  ; val-type: %s\n", val.type
       end       
    }
    hastag
  end
  # ----------------------------------------------------------------------
  # read_v2     reads a version 2.x ID3tag
  
  def read_v2(filename)
    f = File.open(filename, 'r')
    hastag = (f.read(3) == "ID3")
    if hastag
      major = f.getc
      minor = f.getc
      @version = "2." + major.to_s + '.' + minor.to_s
      flag = f.getc
      size = ID3v2headerSize + unmungeSize(f.read(4))
      f.seek(0)
      @raw = f.read(size) 
    else
       @raw = @version = ""
    end
    f.close
    hastag
  end

  # ----------------------------------------------------------------------
  # making data avaliable: 

  def header
      @header
  end

  def raw
      @raw
  end

  def hastag
      @hastag
  end
  def version
      @version
  end

end 
#
## -- Class ID3tag ---------------------------------------------------------------



##### Class ID3frame #############################################################
# 
# ID3v2 frames implementation
#
#   - each frame consists of a header and a data section
#   - the header is of fixed size (it's size is depending on the ID3 version,)
#   - all frames in one ID3v2 header have the same size
#   - 
#
#
#
class ID3frame

  @header = ''
  @data = ''
  @size = 0
  @id3version = 0


  # INPUT  : filehandle, version
  # RETURNS: nil            if  filehandle points to "0" bytes
  #          frame object   if  frame header found
  #
  def initialize(data,version,offset=0)
    
#    if version =~ "1."
#        raise exception
        
     if version == "2.0"
        @headersize = 6
        @name = data[0..2]
        @size = (data[3]*256**2)+(data[2]*256)+data[3]
     else 
        @headersize = 10
        @name = data[0..3]
        @size = (data[4]*256**3)+(data[5]*256**2)+(data[6]*256)+data[7]
        @flags= data[8..9]
     end
     @data = data[@headersize..(@headersize + @size - 1)]
  end

  def data
     @data
  end
  def size
     @size
  end
  def id3version
     @id3version
  end
end 

## -------------------------------------------------------------------------------

end 

#   END of module ID3
##################################################################################
