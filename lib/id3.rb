################################################################################
# id3v2.rb     Ruby Module for handling the following ID3-tag versions:
#                  ID3v1.0 , ID3v1.1,  ID3v2.2.0, ID3v2.3.0, ID3v2.4.0
# 
# Copyright (C) 2002 by Tilo Sloboda <tilo@unixgods.org> 
#
# created:      12 October 2002
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

# ==============================================================================
# EXTENDING CLASS STRING
# ==============================================================================

class String
  #
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

# ==============================================================================
# MODULE ID3
# ==============================================================================

module ID3
  # ----------------------------------------------------------------------------
  #    CONSTANTS
  # ----------------------------------------------------------------------------
  @@RCSid = '$Id: id3.rb,v 1.1 2002/10/28 03:02:10 tilo Exp tilo $'

  ID3v1tagSize = 128;    # ID3v1 and ID3v1.1 have fixed size tags at end of file
  ID3v2headerSize = 10;

  # Struct for storing internal information about ID3v2 frames, and how to handle them
  #
  ID3frame = Struct.new("ID3frame", :name, :headerStartX,  :dataStartX, :dataEndX, :flags)
  ID3frameHandler = Struct.new("ID3frameHandler", :name, :unpack, :pack)
  
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

    #
    # NOTE: values for hash need to be different for ID3v2.x!!
    #       What i really want to do is to create the following entries dynamically 
    #       at startup - so we can have Structs for each entry, which contain the name
    #       of the field-TAG as well as pointers to the pack() and unpack() functions
    
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
                "WWWAUDIOFILE"=>"WAF", "WWWARTIST"=>"WAR", "WWWAUDIOSOURCE"=>"WAS",
                "WWWCOMMERCIALINFO"=>"WCM", "WWWCOPYRIGHT"=>"WCP", "WWWPUBLISHER"=>"WPB",
                "WWWUSER"=>"WXX", "UNIQUEFILEID"=>"UFI",
                "INVOLVEDPEOPLE"=>"IPL", "UNSYNCEDLYRICS"=>"ULT", "COMMENT"=>"COM",
                "CDID"=>"MCI", "EVENTTIMING"=>"ETC", "MPEGLOOKUP"=>"MLL",
                "SYNCEDTEMPO"=>"STC", "SYNCEDLYRICS"=>"SLT", "VOLUMEADJ"=>"RVA",
                "EQUALIZATION"=>"EQU", "REVERB"=>"REV", "PICTURE"=>"PIC",
                "GENERALOBJECT"=>"GEO", "PLAYCOUNTER"=>"CNT", "POPULARIMETER"=>"POP",
                "BUFFERSIZE"=>"BUF", "CRYPTEDMETA"=>"CRM", "AUDIOCRYPTO"=>"CRA",
                "LINKED"=>"LNK"
               } ,
               
    "2.3.0" => {"CONTENTGROUP"=>"TIT1", "TITLE"=>"TIT2", "SUBTITLE"=>"TIT3",
                "ARTIST"=>"TPE1", "BAND"=>"TPE2", "CONDUCTOR"=>"TPE3", "MIXARTIST"=>"TPE4",
                "COMPOSER"=>"TCOM", "LYRICIST"=>"TEXT", "LANGUAGE"=>"TLAN", "CONTENTTYPE"=>"TCON",
                "ALBUM"=>"TALB", "TRACKNUM"=>"TRCK", "PARTINSET"=>"TPOS", "ISRC"=>"TSRC",
                "DATE"=>"TDAT", "YEAR"=>"TYER", "TIME"=>"TIME", "RECORDINGDATES"=>"TRDA",
                "ORIGYEAR"=>"TORY", "SIZE"=>"TSIZ", 
                "BPM"=>"TBPM", "MEDIATYPE"=>"TMED", "FILETYPE"=>"TFLT", "COPYRIGHT"=>"TCOP",
                "PUBLISHER"=>"TPUB", "ENCODEDBY"=>"TENC", "ENCODERSETTINGS"=>"TSSE",
                "SONGLEN"=>"TLEN", "PLAYLISTDELAY"=>"TDLY", "INITIALKEY"=>"TKEY",
                "ORIGALBUM"=>"TOAL", "ORIGFILENAME"=>"TOFN", "ORIGARTIST"=>"TOPE",
                "ORIGLYRICIST"=>"TOLY", "FILEOWNER"=>"TOWN", "NETRADIOSTATION"=>"TRSN",
                "NETRADIOOWNER"=>"TRSO", "USERTEXT"=>"TXXX",
                "WWWAUDIOFILE"=>"WOAF", "WWWARTIST"=>"WOAR", "WWWAUDIOSOURCE"=>"WOAS",
                "WWWCOMMERCIALINFO"=>"WCOM", "WWWCOPYRIGHT"=>"WCOP", "WWWPUBLISHER"=>"WPUB",
                "WWWRADIOPAGE"=>"WORS", "WWWPAYMENT"=>"WPAY", "WWWUSER"=>"WXXX", "UNIQUEFILEID"=>"UFID",
                "INVOLVEDPEOPLE"=>"IPLS", 
                "UNSYNCEDLYRICS"=>"USLT", "COMMENT"=>"COMM", "TERMSOFUSE"=>"USER",
                "CDID"=>"MCDI", "EVENTTIMING"=>"ETCO", "MPEGLOOKUP"=>"MLLT",
                "SYNCEDTEMPO"=>"SYTC", "SYNCEDLYRICS"=>"SYLT", 
                "VOLUMEADJ"=>"RVAD", "EQUALIZATION"=>"EQUA", 
                "REVERB"=>"RVRB", "PICTURE"=>"APIC", "GENERALOBJECT"=>"GEOB",
                "PLAYCOUNTER"=>"PCNT", "POPULARIMETER"=>"POPM", "BUFFERSIZE"=>"RBUF",
                "AUDIOCRYPTO"=>"AENC", "LINKEDINFO"=>"LINK", "POSITIONSYNC"=>"POSS",
                "COMMERCIAL"=>"COMR", "CRYPTOREG"=>"ENCR", "GROUPINGREG"=>"GRID", 
                "PRIVATE"=>"PRIV"
               } ,
               
    "2.4.0" => {"CONTENTGROUP"=>"TIT1", "TITLE"=>"TIT2", "SUBTITLE"=>"TIT3",
                "ARTIST"=>"TPE1", "BAND"=>"TPE2", "CONDUCTOR"=>"TPE3", "MIXARTIST"=>"TPE4",
                "COMPOSER"=>"TCOM", "LYRICIST"=>"TEXT", "LANGUAGE"=>"TLAN", "CONTENTTYPE"=>"TCON",
                "ALBUM"=>"TALB", "TRACKNUM"=>"TRCK", "PARTINSET"=>"TPOS", "ISRC"=>"TSRC",
                "RECORDINGTIME"=>"TDRC", "ORIGRELEASETIME"=>"TDOR",
                "BPM"=>"TBPM", "MEDIATYPE"=>"TMED", "FILETYPE"=>"TFLT", "COPYRIGHT"=>"TCOP",
                "PUBLISHER"=>"TPUB", "ENCODEDBY"=>"TENC", "ENCODERSETTINGS"=>"TSSE",
                "SONGLEN"=>"TLEN", "PLAYLISTDELAY"=>"TDLY", "INITIALKEY"=>"TKEY",
                "ORIGALBUM"=>"TOAL", "ORIGFILENAME"=>"TOFN", "ORIGARTIST"=>"TOPE",
                "ORIGLYRICIST"=>"TOLY", "FILEOWNER"=>"TOWN", "NETRADIOSTATION"=>"TRSN",
                "NETRADIOOWNER"=>"TRSO", "USERTEXT"=>"TXXX",
                "SETSUBTITLE"=>"TSST", "MOOD"=>"TMOO", "PRODUCEDNOTICE"=>"TPRO",
                "ENCODINGTIME"=>"TDEN", "RELEASETIME"=>"TDRL", "TAGGINGTIME"=>"TDTG",
                "ALBUMSORTORDER"=>"TSOA", "PERFORMERSORTORDER"=>"TSOP", "TITLESORTORDER"=>"TSOT",
                "WWWAUDIOFILE"=>"WOAF", "WWWARTIST"=>"WOAR", "WWWAUDIOSOURCE"=>"WOAS",
                "WWWCOMMERCIALINFO"=>"WCOM", "WWWCOPYRIGHT"=>"WCOP", "WWWPUBLISHER"=>"WPUB",
                "WWWRADIOPAGE"=>"WORS", "WWWPAYMENT"=>"WPAY", "WWWUSER"=>"WXXX", "UNIQUEFILEID"=>"UFID",
                "MUSICIANCREDITLIST"=>"TMCL", "INVOLVEDPEOPLE2"=>"TIPL",
                "UNSYNCEDLYRICS"=>"USLT", "COMMENT"=>"COMM", "TERMSOFUSE"=>"USER",
                "CDID"=>"MCDI", "EVENTTIMING"=>"ETCO", "MPEGLOOKUP"=>"MLLT",
                "SYNCEDTEMPO"=>"SYTC", "SYNCEDLYRICS"=>"SYLT", 
                "VOLUMEADJ2"=>"RVA2", "EQUALIZATION2"=>"EQU2",
                "REVERB"=>"RVRB", "PICTURE"=>"APIC", "GENERALOBJECT"=>"GEOB",
                "PLAYCOUNTER"=>"PCNT", "POPULARIMETER"=>"POPM", "BUFFERSIZE"=>"RBUF",
                "AUDIOCRYPTO"=>"AENC", "LINKEDINFO"=>"LINK", "POSITIONSYNC"=>"POSS",
                "COMMERCIAL"=>"COMR", "CRYPTOREG"=>"ENCR", "GROUPINGREG"=>"GRID", 
                "PRIVATE"=>"PRIV",
                "OWNERSHIP"=>"OWNE", "SIGNATURE"=>"SIGN", "SEEKFRAME"=>"SEEK",
                "AUDIOSEEKPOINT"=>"ASPI"
               }
  }
  
  # ----------------------------------------------------------------------------
  #  MODULE FUNCTIONS
  # ----------------------------------------------------------------------------
  module_function

  # check if file has a ID3-tag and which version it is
  # 
  # NOTE: file might be tagged twice! :(
  
  # ----------------------------------------------------------------------------
  # has_v1_tag? 
  #              returns true if v1.0 or v1.1 tag was found 

  def has_v1_tag?(filename)
    hastag     = 0
    
    f = File.open(filename, 'r')
    f.seek(-ID3v1tagSize, IO::SEEK_END)
    if (f.read(3) == "TAG")
      f.seek(-ID3v1tagSize + 125, IO::SEEK_END)
      c = f.getc;                         # this is character 125 of the tag
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
  
  def has_v2_tag?(filename)
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
  @@framename2symbol= Hash.new
  @@framename2symbol["1.0"] = ID3::SUPPORTED_SYMBOLS["1.0"].invert
  @@framename2symbol["1.1"] = ID3::SUPPORTED_SYMBOLS["1.1"].invert
  @@framename2symbol["2.2.0"] = ID3::SUPPORTED_SYMBOLS["2.2.0"].invert
  @@framename2symbol["2.3.0"] = ID3::SUPPORTED_SYMBOLS["2.3.0"].invert
  @@framename2symbol["2.4.0"] = ID3::SUPPORTED_SYMBOLS["2.4.0"].invert
        

  # ----------------------------------------------------------------------------
  #    PRIVATE METHODS   (need to hide those!)
  # ----------------------------------------------------------------------------
  private
  
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
  # ----------------------------------------------------------------------
  #    UNPACKING and PACKING METHODS
  # ----------------------------------------------------------------------------
  def unpack_TXT (frame)
     i = frame.dataStartX
     j = frame.dataEndX
     if @raw[i] == 0
       if s = @raw[i+1..j]
          return @raw[i+1..j].squeeze(" \000").chomp(" ").chomp("\000")
     else 
	 print "\n\nproblem in #{frame.name}\n"
	 return ""
       end
     else 
       return "__UNKNOWN_CODING__"
     end
  end

  # ----------------------------------------------------------------------------
  #    PUBLIC METHODS
  # ----------------------------------------------------------------------------
  public

  def raw
      @raw
  end

  def version
      @version
  end

  def frames
      @frames
  end

  alias old_set []=
  private :old_set
  

  def []=(key,val)
   if @version == ""
     raise ArgumentError, "undefined version of ID3-tag! - set version before accessing components!\n" 
   else
     if ID3::SUPPORTED_SYMBOLS[@version].keys.include?(key)
        old_set(key,val)
     else 
        # exception
        raise ArgumentError, "Incorrect ID3-field \"#{key}\" for ID3 version #{@version}\n" +
                             "\t\tvalid fields are: " + SUPPORTED_SYMBOLS[@version].keys.join(",") +"\n"
     end
   end
  end

  # keys, values, each, etc. come for free with Hash


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
          self[key] = @raw[val].squeeze(" \000").chomp(" ").chomp("\000")
       elsif val.type == Fixnum
          self[key] = @raw[val].to_s
       else 
          printf "unknown key/val : #{key} / #{val}  ; val-type: %s\n", val.type
       end       
    }
    hastag
  end

  # ----------------------------------------------------------------------
  # parse_frame_header
  #
  # each frame consists of a header of fixed length; 
  # depending on the ID3version, either 6 or 10 bytes.
  # and of a data portion which is of variable length,
  # and which contents might not be parsable by us
  #
  # INPUT:   index to where in the @raw data the frame starts
  # RETURNS: if successful parse: 
  #             total size in bytes, ID3frame struct
  #          else:
  #             0, nil
  #
  #
  #          Struct of type ID3frame which contains:
  #                the name, size (in bytes), headerX, 
  #                dataStartX, dataEndX, flags
  #          the data indices point into the @raw data, so we can cut out
  #          and parse the data at a later point in time.
  # 
  #          total frame size = dataEndX - headerX
  #          total header size= dataStartX - headerX
  #          total data size  = dataEndX - dataStartX
  #
  private  
  def parse_frame_header(x)
     framename = ""; flags = nil
     hsize = size = 0
     if @version =~ "^2.2."
        hsize = 6;                     # 2.2.x Header Size is 6 bytes
        header = @raw[x..x+hsize-1]

        framename = header[0..2]
        size = (header[3]*256**2)+(header[4]*256)+header[5]
        flags = nil
     else 
        # for version 2.3.0 and 2.4.0 the header is 10 bytes long
        hsize = 10
        header = @raw[x..x+hsize-1]

        framename = header[0..3]
        size = (header[4]*256**3)+(header[5]*256**2)+(header[6]*256)+header[7]
        flags= header[8..9];        # perhaps we need to parse those flags later
     end

     # if this is a valid frame of known type, we return it's total length and a struct
     # 
     if ID3::SUPPORTED_SYMBOLS[@version].has_value?(framename)
         if !defined? @frames
            @frames = Hash.new ; # dynamically extending this ID3tag instance..
         end
         frame = ID3::ID3frame.new(framename, x, x+hsize , x+hsize + size - 1 , flags)
         @frames[ @@framename2symbol[@version][frame.name] ] = frame
         return size+hsize , frame
     else
         return 0, nil
     end
  end

  public  
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
    #
    # now parse all the frames
    #
    i = ID3v2headerSize; # we start parsing right after the ID3v2 header
    
    while (i < @raw.size) && (@raw[i] != 0)
       len,frame = parse_frame_header(i)
       if len != 0
          i += len
          self[ @@framename2symbol[@version][frame.name] ] = unpack_TXT(frame)
       else
          # finished parsing
          break
       end
    end
    
    hastag
  end

  # ----------------------------------------------------------------------
  # making data avaliable: 

end 
#
## -- Class ID3tag ---------------------------------------------------------------

end
#   END of module ID3
##################################################################################
