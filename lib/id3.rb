################################################################################
# id3.rb  Ruby Module for handling the following ID3-tag versions:
#         ID3v1.0 , ID3v1.1,  ID3v2.2.0, ID3v2.3.0, ID3v2.4.0
# 
# Copyright (C) 2002,2003,2004 by Tilo Sloboda <tilo@unixgods.org> 
#
# created:      12 Oct 2002
# updated:      Time-stamp: <Mon 27-Dec-2004 22:23:49 Tilo Sloboda>
#
# Docs:   http://www.id3.org/id3v2-00.txt
#         http://www.id3.org/id3v2.3.0.txt
#         http://www.id3.org/id3v2.4.0-changes.txt
#         http://www.id3.org/id3v2.4.0-structure.txt
#         http://www.id3.org/id3v2.4.0-frames.txt
#  
#         different versions of ID3 tags, support different fields.
#         See: http://www.unixgods.org/~tilo/ID3v2_frames_comparison.txt
#         See: http://www.unixgods.org/~tilo/ID3/docs/ID3_comparison.html
#
# License:     
#         Freely available under the terms of the OpenSource "Artistic License"
#         in combination with the Addendum A (below)
# 
#         In case you did not get a copy of the license along with the software, 
#         it is also available at:   http://www.unixgods.org/~tilo/artistic-license.html
#
# Addendum A: 
#         THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU!
#         SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
#         REPAIR OR CORRECTION. 
#
#         IN NO EVENT WILL THE COPYRIGHT HOLDERS  BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, 
#         SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY 
#         TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED 
#         INACCURATE OR USELESS OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM 
#         TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF THE COPYRIGHT HOLDERS OR OTHER PARTY HAS BEEN
#         ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
#
# Author's Rant:
#         The author of this ID3-library for Ruby is not responsible in any way for 
#         the definition of the ID3-standards..
#
#         You're lucky though that you can use this little library, rather than having 
#         to parse ID3v2 tags yourself!  Trust me!  At the first glance it doesn't seem
#         to be so complicated, but the ID3v2 definitions are so convoluted and 
#         unnecessarily complicated, with so many useless frame-types, it's a pain to 
#         read the documents describing the ID3 V2.x standards.. and even worse 
#         to implement them..  
#
#         I don't know what these people were thinking... can we make it any more 
#         complicated than that??  ID3 version 2.4.0 tops everything!   If this flag
#         is set and it's a full moon, and an even weekday number, then do this.. 
#         Outch!!!  I assume that's why I don't find any 2.4.0 tags in any of my 
#         MP3-files... seems like noone is writing 2.4.0 tags... iTunes writes 2.3.0
#
#         If you have some files with valid 2.4.0 tags, please send them my way! 
#         Thank you!
#
#-------------------------------------------------------------------------------
#  Module ID3
#    
#    Module Functions:
#       hasID3v1tag?(filename)
#       hasID3v2tag?(filename)
#       removeID3v1tag(filename)
#
#    Classes:
#       File
#       Tag1
#       Tag2
#       Frame
#
################################################################################

# ==============================================================================
# Lading other stuff..
# ==============================================================================

require "md5"

require 'hexdump'                  # load hexdump method to extend class String
require 'invert_hash'              # new invert method for old Hash


class Hash                         # overwrite Hash.invert method
    alias old_invert invert

    def invert
       self.inverse
    end
end


module ID3

    # ----------------------------------------------------------------------------
    #    CONSTANTS
    # ----------------------------------------------------------------------------
    @@RCSid = '$Id: id3.rb,v 1.2 2004/11/29 05:18:44 tilo Exp tilo $'

    ID3v1tagSize     = 128     # ID3v1 and ID3v1.1 have fixed size tags
    ID3v1versionbyte = 125
    ID3v2headerSize  = 10


    SUPPORTED_SYMBOLS = {
    "1.0"   => {"ARTIST"=>33..62 , "ALBUM"=>63..92 ,"TITLE"=>3..32,
                "YEAR"=>93..96 , "COMMENT"=>97..126,"GENREID"=>127,
#               "VERSION"=>"1.0"
               }  ,
    "1.1"   => {"ARTIST"=>33..62 , "ALBUM"=>63..92 ,"TITLE"=>3..32,
                "YEAR"=>93..96 , "COMMENT"=>97..124,
                "TRACKNUM"=>126, "GENREID"=>127,
#                "VERSION"=>"1.1"
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
    # Flags in the ID3-Tag Header:
    
    TAG_HEADER_FLAG_MASK = {  # the mask is inverse, for error detection
                              # those flags are supposed to be zero!
      "2.2.0" =>  0x3F,   # 0xC0 , 
      "2.3.0" =>  0x1F,   # 0xE0 , 
      "2.4.0" =>  0x0F    # 0xF0 
    }
    
    TAG_HEADER_FLAGS = {
      "2.2.0" => { "Unsynchronisation"      => 0x80 ,
                   "Compression"            => 0x40 ,
                 } ,
      "2.3.0" => { "Unsynchronisation"      => 0x80 ,
                   "ExtendedHeader"         => 0x40 ,
                   "Experimental"           => 0x20 ,
                 } ,
      "2.4.0" => { "Unsynchronisation"      => 0x80 ,
                   "ExtendedHeader"         => 0x40 ,
                   "Experimental"           => 0x20 ,
                   "Footer"                 => 0x10 , 
                 }
    }

    # ----------------------------------------------------------------------------
    # Flags in the ID3-Frame Header:
    
    FRAME_HEADER_FLAG_MASK = { # the mask is inverse, for error detection
                               # those flags are supposed to be zero!
      "2.3.0" =>  0x1F1F,   # 0xD0D0 ,
      "2.4.0" =>  0x8FB0    # 0x704F ,
    }
    
    FRAME_HEADER_FLAGS = {
      "2.3.0" => { "TagAlterPreservation"   => 0x8000 ,
                   "FileAlterPreservation"  => 0x4000 ,
                   "ReadOnly"               => 0x2000 ,

                   "Compression"            => 0x0080 ,
                   "Encryption"             => 0x0040 ,
                   "GroupIdentity"          => 0x0020 ,
                 } ,
      "2.4.0" => { "TagAlterPreservation"   => 0x4000 , 
                   "FileAlterPreservation"  => 0x2000 ,
                   "ReadOnly"               => 0x1000 ,

                   "GroupIdentity"          => 0x0040 ,
                   "Compression"            => 0x0008 ,
                   "Encryption"             => 0x0004 ,
                   "Unsynchronisation"      => 0x0002 ,
                   "DataLengthIndicator"    => 0x0001 ,
                 }
    }

    # the FrameTypes are not visible to the user - they are just a mechanism 
    # to define only one parser for multiple FraneNames.. 
    #

    FRAMETYPE2FRAMENAME = {
       "TEXT" => %w(TENTGROUP TITLE SUBTITLE ARTIST BAND CONDUCTOR MIXARTIST COMPOSER LYRICIST LANGUAGE CONTENTTYPE ALBUM TRACKNUM PARTINSET ISRC DATE YEAR TIME RECORDINGDATES ORIGYEAR BPM MEDIATYPE FILETYPE COPYRIGHT PUBLISHER ENCODEDBY ENCODERSETTINGS SONGLEN SIZE PLAYLISTDELAY INITIALKEY ORIGALBUM ORIGFILENAME ORIGARTIST ORIGLYRICIST FILEOWNER NETRADIOSTATION NETRADIOOWNER SETSUBTITLE MOOD PRODUCEDNOTICE ALBUMSORTORDER PERFORMERSORTORDER TITLESORTORDER INVOLVEDPEOPLE), 
       "USERTEXT" => "USERTEXT",
       
       "WEB"      => %w(WWWAUDIOFILE WWWARTIST WWWAUDIOSOURCE WWWCOMMERCIALINFO WWWCOPYRIGHT WWWPUBLISHER WWWRADIOPAGE WWWPAYMENT) , 
       "WWWUSER"  => "WWWUSER",
       "LTEXT"    => "TERMSOFUSE" ,
       "PICTURE"  => "PICTURE" , 
       "UNSYNCEDLYRICS"  => "UNSYNCEDLYRICS" , 
       "COMMENT"  => "COMMENT" , 
       "BINARY"   => %w(PLAYCOUNTER CDID) ,

       # For the following Frames there are no parser stings defined .. the user has access to the raw data
       # The following frames are good examples for completely useless junk which was put into the ID3-definitions.. what were they smoking?
       #
       "UNPARSED"  => %w(UNIQUEFILEID OWNERSHIP SYNCEDTEMPO MPEGLOOKUP REVERB SYNCEDLYRICS CONTENTGROUP POPULARIMETER GENERALOBJECT VOLUMEADJ AUDIOCRYPTO CRYPTEDMETA BUFFERSIZE EVENTTIMING EQUALIZATION LINKED PRIVATE LINKEDINFO POSITIONSYNC GROUPINGREG CRYPTOREG COMMERCIAL SEEKFRAME AUDIOSEEKPOINT SIGNATURE EQUALIZATION2 VOLUMEADJ2 MUSICIANCREDITLIST INVOLVEDPEOPLE2 RECORDINGTIME ORIGRELEASETIME ENCODINGTIME RELEASETIME TAGGINGTIME)
    }

    VARS    = 0
    PACKING = 1

                                #  not sure if it's   Z* or  A*
                                #  A*  does not append a \0 when writing!
                                
    # STILL NEED TO CAREFULLY VERIFY THESE AGAINST THE STANDARDS AND GET TEST-CASES!
    # seems like i have no version 2.4.x ID3-tags!! If you have some, send them my way!

    FRAME_PARSER = {
      "TEXT"      => [ %w(encoding text) , 'CZ*' ] ,
      "USERTEXT"  => [ %w(encoding description value) , 'CZ*Z*' ] ,

      "PICTURE"   => [ %w(encoding mimeType pictType description picture) , 'CZ*CZ*a*' ] ,

      "WEB"       => [ "url" , 'Z*' ] ,
      "WWWUSER"   => [ %w(encoding description url) , 'CZ*Z*' ] ,

      "LTEXT"     => [ %w(encoding language text) , 'CZ*Z*' ] ,
      "UNSYNCEDLYRICS"    => [ %w(encoding language content text) , 'Ca3Z*Z*' ] ,
      "COMMENT"   => [ %w(encoding language short long) , 'Ca3Z*Z*' ] ,
      "BINARY"    => [ "binary" , 'a*' ] ,
      "UNPARSED"  => [ "raw" , 'a*' ]       # how would we do value checking for this?
    }
    
    # ----------------------------------------------------------------------------
    # MODULE VARIABLES
    # ----------------------------------------------------------------------------
    Symbol2framename = ID3::SUPPORTED_SYMBOLS
    Framename2symbol = Hash.new
    Framename2symbol["1.0"]   = ID3::SUPPORTED_SYMBOLS["1.0"].invert
    Framename2symbol["1.1"]   = ID3::SUPPORTED_SYMBOLS["1.1"].invert
    Framename2symbol["2.2.0"] = ID3::SUPPORTED_SYMBOLS["2.2.0"].invert
    Framename2symbol["2.3.0"] = ID3::SUPPORTED_SYMBOLS["2.3.0"].invert
    Framename2symbol["2.4.0"] = ID3::SUPPORTED_SYMBOLS["2.4.0"].invert

    FrameType2FrameName = ID3::FRAMETYPE2FRAMENAME

    FrameName2FrameType = FrameType2FrameName.invert
    
    # ----------------------------------------------------------------------------
    # the following piece of code is just for debugging, to sanity-check that all
    # the FrameSymbols map back to a FrameType -- otherwise the library code will
    # break if we encounter a Frame which can't be mapped to a FrameType..
    # ----------------------------------------------------------------------------
    #
    # ensure we have a FrameType defined for each FrameName, otherwise
    # code might break later..
    #

#    print "\nMISSING SYMBOLS:\n"
    
    (ID3::Framename2symbol["2.2.0"].values +
     ID3::Framename2symbol["2.3.0"].values +
     ID3::Framename2symbol["2.4.0"].values).uniq.each { |symbol|
#       print "#{symbol} " if ! ID3::FrameName2FrameType[symbol]
      print "SYMBOL: #{symbol} not defined!\n" if ! ID3::FrameName2FrameType[symbol]
    }
#    print "\n\n"
    
    # ----------------------------------------------------------------------------
    # MODULE FUNCTIONS:
    # ----------------------------------------------------------------------------
    # The ID3 module functions are to query or modify files directly.
    # They give direct acess to files, and don't parse the tags, despite their headers
    #
    #
    
    # ----------------------------------------------------------------------------
    # hasID3v1tag? 
    #              returns string with version 1.0 or 1.1 if tag was found 
    #              returns false  otherwise

    def ID3.hasID3v1tag?(filename)
      hasID3v1tag     = false

      # be careful with empty or corrupt files..
      return false if File.size(filename) < ID3v1tagSize

      f = File.open(filename, 'r')
      f.seek(-ID3v1tagSize, IO::SEEK_END)
      if (f.read(3) == "TAG")
        f.seek(-ID3v1tagSize + ID3v1versionbyte, IO::SEEK_END)
        c = f.getc;                         # this is character 125 of the tag
        if (c == 0) 
           hasID3v1tag = "1.1"
        else
           hasID3v1tag = "1.0"
        end
      end
      f.close
      return hasID3v1tag
    end

    # ----------------------------------------------------------------------------
    # hasID3v2tag? 
    #              returns string with version 2.2.0, 2.3.0 or 2.4.0 if tag found
    #              returns false  otherwise

    def ID3.hasID3v2tag?(filename)
      hasID3v2tag     = false

      f = File.open(filename, 'r')
      if (f.read(3) == "ID3")
         major = f.getc
         minor = f.getc
         version   = "2." + major.to_s + '.' + minor.to_s
         hasID3v2tag = version
      end
      f.close
      return hasID3v2tag
    end

    # ----------------------------------------------------------------------------
    # hasID3tag? 
    #              returns string with all versions found, space separated
    #              returns false  otherwise
    
    def ID3.hasID3tag?(filename)
      v1 = ID3.hasID3v1tag?(filename)
      v2 = ID3.hasID3v2tag?(filename)

      return false if !v1 && !v2 
      return v1    if !v2
      return v2    if !v1
      return "#{v1} #{v2}"
    end

    # ----------------------------------------------------------------------------
    # removeID3v1tag
    #            returns  nil  if no v1 tag was found, or it couldn't be removed
    #            returns  true if v1 tag found and it was removed..
    #
    # in the future:
    #            returns  ID3.Tag1  object if a v1 tag was found and removed

    def ID3.removeID3v1tag(filename)
      stat = File.stat(filename)
      if stat.file? && stat.writable? && ID3.hasID3v1tag?(filename)
         
         # CAREFUL: this does not check if there really is a valid tag:
         
         newsize = stat.size - ID3v1tagSize
         File.open(filename, "r+") { |f| f.truncate(newsize) }

         return true
      else
         return nil
      end
    end
    # ----------------------------------------------------------------------------
    
        
    # ==============================================================================
    # Class AudioFile    may call this ID3File
    #
    #    reads and parses audio files for tags
    #    writes audio files and attaches dumped tags to it..
    #    revert feature would be nice to have..
    # 
    #    If we query and AudioFile object, we query what's currently associated with it
    #    e.g. we're not querying the file itself, but the perhaps modified tags
    #    To query the file itself, use the module functions

    class AudioFile

      attr_reader :audioStartX , :audioEndX     # begin and end indices of audio data in file
      attr_reader :audioMD5sum                  # MD5sum of the audio portion of the file

      attr_reader :pwd,          :filename      # PWD and relative path/name how file was first referenced
      attr_reader :dirname,      :basename      # absolute dirname and basename of the file (computed)

      attr_accessor :tagID3v1, :tagID3v2
      attr_reader   :hasID3tag                  # either false, or a string with all version numbers found

      # ----------------------------------------------------------------------------
      # initialize
      #
      #   AudioFile.new   does NOT open the file, but scans it and parses the info

      #   e.g.:  ID3::AudioFile.new('mp3/a.mp3')

      def initialize(filename)
          @filename     = filename      # similar to path method from class File, which is a mis-nomer!
          @pwd          = ENV["PWD"]
          @dirname      = File.dirname( "#{@pwd}/#{@filename}" )   # just sugar
          @basename     = File.basename( "#{@pwd}/#{@filename}" )  # just sugar
          
          @tagID3v1     = nil
          @tagID3v2     = nil
          
          audioStartX   = 0
          audioEndX     = File.size(filename)

          if ID3.hasID3v1tag?(@filename)
              @tagID3v1 = Tag1.new
              @tagID3v1.read(@filename)

              audioEndX -= ID3::ID3v1tagSize
          end
          if ID3.hasID3v2tag?(@filename) 
              @tagID3v2 = Tag2.new
              @tagID3v2.read(@filename)

              audioStartX = @tagID3v2.raw.size
          end
          
          # audioStartX audioEndX indices into the file need to be set
          @audioStartX = audioStartX 
          @audioEndX   = audioEndX
          
          # user may compute the MD5sum of the audio content later..
          # but we're only doing this if the user requests it..

          @audioMD5sum = nil
      end
      
      # ----------------------------------------------------------------------------
      # audioMD5sum
      #     if the user tries to access @audioMD5sum, it will be computed for him, 
      #     unless it was previously computed. We try to calculate that only once 
      #     and on demand, because it's a bit expensive to compute..
      
      def audioMD5sum
         if ! @audioMD5sum 
            
            File.open( File.join(@dirname,@basename) ) { |f|
              f.seek(@audioStartX)
              @audioMD5sum = MD5.new( f.read(@audioEndX - @audioStartX + 1) )
            }

         end
         @audioMD5sum
      end
      # ----------------------------------------------------------------------------
      # writeMD5sum
      #     write the filename and MD5sum of the audio portion into an ascii file 
      #     in the same location as the audio file, but with suffix .md5
      #
      #     computes the @audioMD5sum, if it wasn't previously computed..

      def writeMD5sum
      
         self.audioMD5sum if ! @audioMD5sum  # compute MD5sum if it's not computed yet
         
         base = @basename.sub( /(.)\.[^.]+$/ , '\1')
         base += '.md5'
         File.open( File.join(@dirname,base) ,"w") { |f| 
            f.printf("%s   %s\n",  File.join(@dirname,@basename), @audioMD5sum)
         }
         @audioMD5sum
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
      def version
         a = Array.new
         a.push(@tagID3v1.version) if @tagID3v1
         a.push(@tagID3v2.version) if @tagID3v2
         return nil   if a == []
         a.join(' ') 
      end
      alias versions version
      # ----------------------------------------------------------------------------

         
      
    end   # of class AudioFile

    
    # ==============================================================================
    # Class RestrictedOrderedHash
    
    class RestrictedOrderedHash < Hash

        attr_accessor :count , :order, :locked

        def lock
          @locked = true
        end
        
        def initialize 
          @locked = false
          @count  = 0
          @order  = []
          super
        end

        alias old_store []=

        def []= (key,val)
          if self[key]
             self.old_store(key,val) 
          else
             if @locked
                # we're not allowed to add new keys!
               raise ArgumentError, "You can not add new keys! The ID3-frame #{@name} has fixed entries!\n" +
               "               valid key are: " + self.keys.join(",") +"\n"

             else 
                @count += 1
                @order += [key]
                self.old_store(key,val)
             end
          end
        end
        
        def values
          array = []
          @order.each { |key|
             array.push self[key]
          }
          array
        end

        # returns the human-readable ordered hash in correct order .. ;-)
        
        def inspect
           first = true
           str = "{"
           self.order.each{ |key|
             str += ", " if !first
             str += key.inspect
             str += "=>"
             str += (self[key]).inspect
             first = false
           }
           str +="}"
        end
        
        # users can not delete entries from a locked hash..
        
        alias old_delete delete
        
        def delete (key)
           if !@locked
              old_delete(key)
              @order.delete(key)
           end
        end
        
    end
    
    
    
    # ==============================================================================
    # Class GenericTag
    #
    # as per ID3-definition, the frames are in no fixed order! that's why Hash is OK

    class GenericTag < Hash        ###### should this be RestrictedOrderedHash as well? 
       attr_reader :version, :raw

       # these definitions are to prevent users from inventing their own field names..
       # but on the other hand, they should be able to create a new valid field, if
       # it's not yet in the current tag, but it's valid for that ID3-version...
       # ... so hiding this, is not enough!
       
       alias old_set []=
       private :old_set
  
       # ----------------------------------------------------------------------
       def []=(key,val)
        if @version == ""
          raise ArgumentError, "undefined version of ID3-tag! - set version before accessing components!\n" 
        else
          if ID3::SUPPORTED_SYMBOLS[@version].keys.include?(key)
             old_set(key,val)
          else 
             # exception
             raise ArgumentError, "Incorrect ID3-field \"#{key}\" for ID3 version #{@version}\n" +
             "               valid fields are: " + SUPPORTED_SYMBOLS[@version].keys.join(",") +"\n"
          end
        end
       end
       # ----------------------------------------------------------------------
       # convert the 4 bytes found in the id3v2 header and return the size
       private
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
       private
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
        
    end # of class GenericTag
    
    # ==============================================================================
    # Class Tag1    ID3 Version 1.x Tag
    #
    #      parses ID3v1 tags from a binary array
    #      dumps  ID3v1 tags into a binary array
    #      allows to modify tag's contents

    class Tag1 < GenericTag

       # ----------------------------------------------------------------------
       # read     reads a version 1.x ID3tag
       #
       #     30 title
       #     30 artist
       #     30 album
       #      4 year
       #     30 comment
       #      1 genre

       def read(filename)
         f = File.open(filename, 'r')
         f.seek(-ID3::ID3v1tagSize, IO::SEEK_END)
         hastag = (f.read(3) == 'TAG')
         if hastag
           f.seek(-ID3::ID3v1tagSize, IO::SEEK_END)
           @raw = f.read(ID3::ID3v1tagSize)

#           self.parse!(raw)    # we should use "parse!" instead of re-coding everything..

           if (raw[ID3v1versionbyte] == 0) 
              @version = "1.1"
           else
              @version = "1.0"
           end
         else
           @raw = @version = nil
         end
         f.close
         #
         # now parse all the fields

         ID3::SUPPORTED_SYMBOLS[@version].each{ |key,val|
            if val.class == Range
               self[key] = @raw[val].squeeze(" \000").chomp(" ").chomp("\000")
            elsif val.class == Fixnum
               self[key] = @raw[val].to_s
            else 
               # this can't happen the way we defined the hash..
#              printf "unknown key/val : #{key} / #{val}  ; val-type: %s\n", val.type
            end       
         }
         hastag
       end
       # ----------------------------------------------------------------------
       # write    writes a version 1.x ID3tag
       #
       # not implemented yet..
       #
       # need to loacte old tag, and remove it, then append new tag..
       #
       # always upgrade version 1.0 to 1.1 when writing
 
       
       # ----------------------------------------------------------------------
       # this routine modifies self, e.g. the Tag1 object
       #
       # tag.parse!(raw)   returns boolean value, showing if parsing was successful
       
       def parse!(raw)

         return false    if raw.size != ID3::ID3v1tagSize

         if (raw[ID3v1versionbyte] == 0) 
            @version = "1.1"
         else
            @version = "1.0"
         end

         self.clear    # remove all entries from Hash, we don't want left-overs..

         ID3::SUPPORTED_SYMBOLS[@version].each{ |key,val|
            if val.class == Range
               self[key] = raw[val].squeeze(" \000").chomp(" ").chomp("\000")
            elsif val.class == Fixnum
               self[key] = raw[val].to_s
            else 
               # this can't happen the way we defined the hash..
#              printf "unknown key/val : #{key} / #{val}  ; val-type: %s\n", val.class
            end       
         }
         @raw = raw
         return true
       end
       # ----------------------------------------------------------------------
       # dump version 1.1 ID3 Tag into a binary array
       #
       # although we provide this method, it's stongly discouraged to use it, 
       # because ID3 version 1.x tags are inferior to version 2.x tags, as entries
       # are often truncated and hence often useless..
       
       def dump
         zeroes = "\0" * 32
         raw = "\0" * ID3::ID3v1tagSize
         raw[0..2] = 'TAG'

         self.each{ |key,value|

           range = ID3::Symbol2framename['1.1'][key]

           if range.class == Range 
              length = range.last - range.first + 1
              paddedstring = value + zeroes
              raw[range] = paddedstring[0..length-1]
           elsif range.class == Fixnum
              raw[range] = value.to_i
           else
              # this can't happen the way we defined the hash..
              next
           end
         }

         return raw
       end
       # ----------------------------------------------------------------------
    end  # of class Tag1
    
    # ==============================================================================
    # Class Tag2    ID3 Version 2.x.y Tag
    #
    #      parses ID3v2 tags from a binary array
    #      dumps  ID3v2 tags into a binary array
    #      allows to modify tag's contents
    #
    #      as per definition, the frames are in no fixed order
    
    class Tag2 < GenericTag
      
      attr_reader :rawflags, :flags
      
      def initalize
         @rawflags = 0
         @flags    = {}
         super
      end
      
      def read(filename)
          f = File.open(filename, 'r')
          hastag = (f.read(3) == "ID3")
          if hastag
            major = f.getc
            minor = f.getc
            @version = "2." + major.to_s + '.' + minor.to_s
            @rawflags = f.getc
            size = ID3::ID3v2headerSize + unmungeSize(f.read(4))
            f.seek(0)
            @raw = f.read(size) 
            
            # parse the raw flags:
            if (@rawflags & TAG_HEADER_FLAG_MASK[@version] != 0)
               # in this case we need to skip parsing the frame... and skip to the next one...
               wrong = @rawflags & TAG_HEADER_FLAG_MASK[@version]
               error = printf "ID3 version %s header flags 0x%X contain invalid flags 0x%X !\n", @version, @rawflags, wrong
               raise ArgumentError, error
             end

             @flags = Hash.new

             TAG_HEADER_FLAGS[@version].each{ |key,val|
               # only define the flags which are set..
               @flags[key] = true   if  (@rawflags & val == 1)
             }
            
            
          else
            @raw = nil
            @version = nil
            return false
          end
          f.close
          #
          # now parse all the frames
          #
          i = ID3::ID3v2headerSize; # we start parsing right after the ID3v2 header

          while (i < @raw.size) && (@raw[i] != 0)
             len,frame = parse_frame_header(i)   # this will create the correct frame
             if len != 0
                i += len
             else
                break
             end
          end

          hastag
      end
    
      # ----------------------------------------------------------------------
      # write
      #
      # writes and replaces existing ID3-v2-tag if one is present
      # Careful, this does NOT merge or append, it overwrites!
      
      def write(filename)
         # check how long the old ID3-v2 tag is
         
         # dump ID3-v2-tag
         
         # append old audio to new tag
         
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
         size = 0
         
         if @version =~ /^2\.2\./
            frameHeaderSize = 6                     # 2.2.x Header Size is 6 bytes
            header = @raw[x..x+frameHeaderSize-1]

            framename = header[0..2]
            size = (header[3]*256**2)+(header[4]*256)+header[5]
            flags = nil
#            printf "frame: %s , size: %d\n", framename , size

         elsif @version =~ /^2\.[34]\./
            # for version 2.3.0 and 2.4.0 the header is 10 bytes long
            frameHeaderSize = 10
            header = @raw[x..x+frameHeaderSize-1]

            framename = header[0..3]
            size = (header[4]*256**3)+(header[5]*256**2)+(header[6]*256)+header[7]
            flags= header[8..9]
#            printf "frame: %s , size: %d, flags: %s\n", framename , size, flags

         else
            # we can't parse higher versions
            return 0, false
         end

         # if this is a valid frame of known type, we return it's total length and a struct
         # 
         if ID3::SUPPORTED_SYMBOLS[@version].has_value?(framename)
             frame = ID3::Frame.new(self, framename, x, x+frameHeaderSize , x+frameHeaderSize + size - 1 , flags)
             self[ Framename2symbol[@version][frame.name] ] = frame
             return size+frameHeaderSize , frame
         else
             return 0, nil
         end
      end
      # ----------------------------------------------------------------------
      # dump a ID3-v2 tag into a binary array
      
      public      
      def dump
        data = ""

        # dump all the frames
        self.each { |framename,framedata|
           data << framedata.dump
        }
        # add some padding perhaps
        data << "\0" * 32
        
        # calculate the complete length of the data-section 
        size = mungeSize(data.size)
        
        major,minor = @version.sub(/^2\.([0-9])\.([0-9])/, '\1 \2').split
        
        # prepend a valid ID3-v2.x header to the data block
        header = "ID3" << major.to_i << minor.to_i << @rawflags << size[0] << size[1] << size[2] << size[3]
 
        header + data
      end
      # ----------------------------------------------------------------------

    end  # of class Tag2
    
    # ==============================================================================
    # Class Frame   ID3 Version 2.x.y Frame
    #
    #      parses ID3v2 frames from a binary array
    #      dumps  ID3v2 frames into a binary array
    #      allows to modify frame's contents if the frame was decoded..
    #
    # NOTE:   right now the class Frame is derived from Hash, which is wrong..
    #         It should really be derived from something like RestrictedOrderedHash
    #         ... a new class, which preserves the order of keys, and which does 
    #         strict checking that all keys are present and reference correct values!
    #         e.g.   frames["COMMENT"]
    #         ==>  {"encoding"=>Byte, "language"=>Chars3, "text1"=>String, "text2"=>String}
    #
    #         e.g.  user should be able to create a new frame , like: 
    #              tag2.frames["COMMENT"] = "right side"
    #
    #         and the following checks should be done:
    #
    #            1) if "COMMENT" is a correct key for tag2
    #            2) if the "right side" contains the correct keys
    #            3) if the "right side" contains the correct value for each key
    #
    #         In the simplest case, the "right side" might be just a string, 
    #         but for most FrameTypes, it's a complex datastructure.. and we need
    #         to check it for correctness before doing the assignment..
    #
    # NOTE2:  the class Tag2 should have hash-like accessor functions to let the user
    #         easily access frames and their contents..
    #
    #         e.g.  tag2[framename] would really access tag2.frames[framename]
    #
    #         and if that works, we can make tag2.frames private and hidden!
    #
    #         This means, that when we generate the parse and dump routines dynamically, 
    #         we may want to create the corresponding accessor methods for Tag2 class 
    #         as well...? or are generic ones enough?
    #

    class Frame < RestrictedOrderedHash

        attr_reader :name, :version
        attr_reader :headerStartX, :dataStartX, :dataEndX, :rawdata, :rawheader  # debugging only

        # ----------------------------------------------------------------------
        # return the complete raw frame
        
        def raw
          return @rawheader + @rawdata
        end    
        # ----------------------------------------------------------------------
        alias old_init initialize
        
        def initialize(tag, name, headerStartX, dataStartX, dataEndX, flags)
           @name = name
           @headerStartX = headerStartX
           @dataStartX   = dataStartX
           @dataEndX     = dataEndX

           @rawdata   = tag.raw[dataStartX..dataEndX]
           @rawheader = tag.raw[headerStartX..dataStartX-1]

           # initialize the super class..
           old_init
           
           # parse the darn flags, if there are any..

           @version = tag.version  # caching..
           case @version
             when /2\.2\.[0-9]/
                # no flags, no extra attributes necessary

             when /2\.[34]\.0/
                
                # dynamically create attributes and reader functions:
                instance_eval <<-EOB
                   class << self 
                      attr_reader :rawflags, :flags
                   end
                EOB
                
                @rawflags = flags.to_i   # preserve the raw flags (for debugging only)

                if (flags.to_i & FRAME_HEADER_FLAG_MASK[@version] != 0)
                   # in this case we need to skip parsing the frame... and skip to the next one...
                   wrong = flags.to_i & FRAME_HEADER_FLAG_MASK[@version]
                   error = printf "ID3 version %s frame header flags 0x%X contain invalid flags 0x%X !\n", @version, flags, wrong
                   raise ArgumentError, error
                end

                @flags = Hash.new
                
                FRAME_HEADER_FLAGS[@version].each{ |key,val|
                  # only define the flags which are set..
                  @flags[key] = true   if  (flags.to_i & val == 1)
                }
                
             else
                raise ArgumentError, "ID3 version #{@version} not recognized when parsing frame header flags\n"
           end # parsing flags
        
           # generate method for parsing data
           
           instance_eval <<-EOB
              class << self

                 def parse
                    # here we GENERATE the code to parse, dump and verify  methods
                 
                    vars,packing = ID3::FRAME_PARSER[ ID3::FrameName2FrameType[ ID3::Framename2symbol[self.version][self.name]] ]

                    # debugging print-out:

                    if vars.class == Array
                       vars2 = vars.join(",") 
                    else
                       vars2 = vars
                    end

                    values = self.rawdata.unpack(packing)
                    vars.each { |key|
                       self[key] = values.shift
                    }
                    self.lock   # lock the OrderedHash
                 end

                 def dump
                    vars,packing = ID3::FRAME_PARSER[ ID3::FrameName2FrameType[ ID3::Framename2symbol[self.version][self.name]] ]
                    
                    data = self.values.pack(packing)     # we depend on an OrderedHash, so the values are in the correct order!!!
                    header  = self.name.dup         # we want the value! not the reference!!
                    len     = data.length
                    if self.version =~ /^2\.2\./
                       byte2,rest = len.divmod(256**2)
                       byte1,byte0 = rest.divmod(256)

                       header << byte2 << byte1 << byte0

                    elsif self.version =~ /^2\.[34]\./          # 10-byte header
                       byte3,rest = len.divmod(256**3)
                       byte2,rest = rest.divmod(256**2)
                       byte1,byte0 = rest.divmod(256)            

                       flags1,flags0 = self.rawflags.divmod(256)
                       
                       header << byte3 << byte2 << byte1 << byte0 << flags1 << flags0
                    end
                    header << data
                 end
              end
           EOB
           self.parse           # now we're using the just defined parsing routine

           self
        end
        # ----------------------------------------------------------------------

       
    
    end  # of class Frame

    # ==============================================================================
    


end   # of module ID3
