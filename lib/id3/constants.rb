module ID3
  
  # ----------------------------------------------------------------------------
  #    CONSTANTS
  # ----------------------------------------------------------------------------
  Version = '1.0.0_pre4'

  ID3v1tagSize     = 128     # ID3v1 and ID3v1.1 have fixed size tags
  ID3v1versionbyte = 125

  ID3v2headerSize  = 10
  ID3v2major       =  3
  ID3v2minor       =  4
  ID3v2flags       =  5
  ID3v2tagSize     =  6


  VERSIONS = 
    SUPPORTED_VERSIONS = ["1.0", "1.1", "2.2.0", "2.3.0", "2.4.0"]

  SUPPORTED_SYMBOLS = {
      "1.0"   => {
      "ARTIST"=>33..62 , "ALBUM"=>63..92 ,"TITLE"=>3..32,
      "YEAR"=>93..96 , "COMMENT"=>97..126,"GENREID"=>127,
    #               "VERSION"=>"1.0"
    }  ,
    "1.1"   => {
      "ARTIST"=>33..62 , "ALBUM"=>63..92 ,"TITLE"=>3..32,
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
    "2.2.0" => { 
      "Unsynchronisation"      => 0x80 ,
      "Compression"            => 0x40 ,
    } ,
    "2.3.0" => { 
      "Unsynchronisation"      => 0x80 ,
      "ExtendedHeader"         => 0x40 ,
      "Experimental"           => 0x20 ,
    } ,
    "2.4.0" => { 
      "Unsynchronisation"      => 0x80 ,
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
    "2.3.0" => { 
      "TagAlterPreservation"   => 0x8000 ,
      "FileAlterPreservation"  => 0x4000 ,
      "ReadOnly"               => 0x2000 ,

      "Compression"            => 0x0080 ,
      "Encryption"             => 0x0040 ,
      "GroupIdentity"          => 0x0020 ,
    } ,
    "2.4.0" => { 
      "TagAlterPreservation"   => 0x4000 , 
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

    "PLAYCOUNTER" => "PLAYCOUNTER" , 
    "POPULARIMETER" => "POPULARIMETER", 

    "BINARY"   => %w( CDID ) , # Cee Dee I Dee

    # For the following Frames there are no parser stings defined .. the user has access to the raw data
    # The following frames are good examples for completely useless junk which was put into the ID3-definitions.. what were they smoking?
    #
    "UNPARSED"  => %w(UNIQUEFILEID OWNERSHIP SYNCEDTEMPO MPEGLOOKUP REVERB SYNCEDLYRICS CONTENTGROUP GENERALOBJECT VOLUMEADJ AUDIOCRYPTO CRYPTEDMETA BUFFERSIZE EVENTTIMING EQUALIZATION LINKED PRIVATE LINKEDINFO POSITIONSYNC GROUPINGREG CRYPTOREG COMMERCIAL SEEKFRAME AUDIOSEEKPOINT SIGNATURE EQUALIZATION2 VOLUMEADJ2 MUSICIANCREDITLIST INVOLVEDPEOPLE2 RECORDINGTIME ORIGRELEASETIME ENCODINGTIME RELEASETIME TAGGINGTIME)
  }

  VARS    = 0
  PACKING = 1

  # ----------------------------------------------------------------------------
  # String Encodings:  See id3v2.4.0-structure document, at section 4.
  #                    see also: http://en.wikipedia.org/wiki/ID3#ID3v2_Chapters
  #
  #   Frames that allow different types of text encoding contains a text
  #   encoding description byte. Possible encodings:
  #
  #     $00   ISO-8859-1 [ISO-8859-1]. Terminated with $00. (ASCII)
  #     $01   [UCS-2] in ID3v2.2,ID3v2.3  / UTF-16 [UTF-16] encoded Unicode [UNICODE] with BOM All in ID3v2.4
  #           strings in the same frame SHALL have the same byteorder.
  #           Terminated with $00 00.
  #     $02   UTF-16BE [UTF-16] encoded Unicode [UNICODE] without BOM. (ID3v2.4 only)
  #           Terminated with $00 00.
  #     $03   UTF-8 [UTF-8] encoded Unicode [UNICODE]. Terminated with $00.  (ID3v2.4 only)

  TEXT_ENCODINGS = ["ISO-8859-1", "UTF-16", "UTF-16BE", "UTF-8"]

  # to get the BYTE-code for the encoding type: TEXT_ENCODINGS.index( string.encoding.to_s ).chr
  # to read the string :    .force_encoding( Encoding::whatever )
  # in Ruby 1.9 : Encoding::UTF_8 , Encoding::UTF_16BE, Encoding::ISO_8859_1
  # BOM: see: http://www.websina.com/bugzero/kb/unicode-bom.html
  # ----------------------------------------------------------------------------

  #  not sure if it's   Z* or  A*
  #  A*  does not append a \0 when writing!
  
  # STILL NEED TO GET MORE TEST-CASES! e.g. Japanese ID3-Tags! or other encodings..
  # seems like i have no version 2.4.x ID3-tags!! If you have some, send them my way!

  # NOTE: please note that all the first array entries need to be hashes, in order for Ruby 1.9 to handle this correctly!

  FRAME_PARSER = {
    "TEXT"      => [ %w(encoding text) , 'CZ*' ] ,
    "USERTEXT"  => [ %w(encoding description value) , 'CZ*Z*' ] ,

    "PICTURE"   => [ %w(encoding mime_type pict_type description picture) , 'CZ*CZ*a*' ] ,

    "WEB"       => [ %w(url) , 'Z*' ] ,
    "WWWUSER"   => [ %w(encoding description url) , 'CZ*Z*' ] ,

    "LTEXT"     => [ %w(encoding language text) , 'CZ*Z*' ] ,
    "UNSYNCEDLYRICS"    => [ %w(encoding language content text) , 'Ca3Z*Z*' ] ,
    "COMMENT"   => [ %w(encoding language short long) , 'Ca3Z*Z*' ] ,

    "PLAYCOUNTER"  =>  [%w(counter), 'C*'] ,
    "POPULARIMETER" => [%w(email rating counter), 'Z*CC*'] ,

    "BINARY"    => [ %w(binary) , 'a*' ] ,
    "UNPARSED"  => [ %w(raw) , 'a*' ]       # how would we do value checking for this?
  }
  
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
  
end

