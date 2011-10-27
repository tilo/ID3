module ID3

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

    def initialize
      super
      @rawflags = 0
      @flags    = {}
      @version  = '2.3.0'   # default version
    end

    def read_from_buffer(string)
      has_tag = string =~ /^ID3/
      if has_tag
        major = string.getbyte(ID3::ID3v2major)
        minor = string.getbyte(ID3::ID3v2minor)
        @version  = "2." + major.to_s + '.' + minor.to_s
        @rawflags = string.getbyte(ID3::ID3v2flags)
        size =  ID3::ID3v2headerSize + ID3.unmungeSize( string[ID3::ID3v2tagSize..ID3::ID3v2tagSize+4] )
        return false if string.size < size
        @raw = string[0...size]
        # parse the raw flags:
        if (@rawflags & ID3::TAG_HEADER_FLAG_MASK[@version] != 0)
          # in this case we need to skip parsing the frame... and skip to the next one...
          wrong = @rawflags & ID3::TAG_HEADER_FLAG_MASK[@version]
          error = printf "ID3 version %s header flags 0x%X contain invalid flags 0x%X !\n", @version, @rawflags, wrong
          raise ArgumentError, error
        end
        
        @flags = Hash.new
        
        ID3::TAG_HEADER_FLAGS[@version].each{ |key,val|
          # only define the flags which are set..
          @flags[key] = true   if  (@rawflags & val == 1)
        }
      else
        @raw = nil
        @version = nil
        return false
      end
      #
      # now parse all the frames
      #
      i = ID3::ID3v2headerSize; # we start parsing right after the ID3v2 header
      
      while (i < @raw.size) && (@raw.getbyte(i) != 0)
        len,frame = parse_frame_header(i)   # this will create the correct frame
        if len != 0
          i += len
        else
          break
        end
      end
      
      has_tag
    end

    def read_from_file(filename)
      f = File.open(filename, 'rb:BINARY')
      has_tag = (f.read(3) == "ID3")
      if has_tag
        major = f.get_byte
        minor = f.get_byte
        @version = "2." + major.to_s + '.' + minor.to_s
        @rawflags = f.get_byte
        size = ID3::ID3v2headerSize + unmungeSize(f.read(4))  # was read_bytes, which was a BUG!!
        f.seek(0)
        @raw = f.read(size) 
        
        # parse the raw flags:
        if (@rawflags & ID3::TAG_HEADER_FLAG_MASK[@version] != 0)
          # in this case we need to skip parsing the frame... and skip to the next one...
          wrong = @rawflags & ID3::TAG_HEADER_FLAG_MASK[@version]
          error = printf "ID3 version %s header flags 0x%X contain invalid flags 0x%X !\n", @version, @rawflags, wrong
          raise ArgumentError, error
        end
        
        @flags = Hash.new
        
        ID3::TAG_HEADER_FLAGS[@version].each{ |key,val|
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
      
      while (i < @raw.size) && (@raw.getbyte(i) != 0)
        len,frame = parse_frame_header(i)   # this will create the correct frame
        if len != 0
          i += len
        else
          break
        end
      end
      has_tag
    end
    alias read read_from_file
    
    # ----------------------------------------------------------------------
    # write
    #
    # writes and replaces existing ID3-v2-tag if one is present
    # Careful, this does NOT merge or append, it overwrites!
    
    # not yet implemented, because AudioFile.write does the job better
    
    #      def write(filename)
    # check how long the old ID3-v2 tag is
    
    # dump ID3-v2-tag
    
    # append old audio to new tag
    
    #      end
    
    # ----------------------------------------------------------------------------
    # writeID3v2
    #    just writes the ID3v2 tag by itself into a file, no audio data is written
    #
    #    for backing up ID3v2 tags and debugging only..
    #
    
    #      def writeID3v2
    
    #      end
    
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
        size = (header.getbyte(3)*256**2)+(header.getbyte(4)*256)+header.getbyte(5)
        flags = nil
        #            printf "frame: %s , size: %d\n", framename , size

      elsif @version =~ /^2\.[34]\./
        # for version 2.3.0 and 2.4.0 the header is 10 bytes long
        frameHeaderSize = 10
        header = @raw[x..x+frameHeaderSize-1]

        #           puts @raw.inspect

        framename = header[0..3]
        size = (header.getbyte(4)*256**3)+(header.getbyte(5)*256**2)+(header.getbyte(6)*256)+header.getbyte(7)
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
        self[ ID3::Framename2symbol[@version][frame.name] ] = frame
        return size+frameHeaderSize , frame
      else
        return 0, nil
      end
    end
    # ----------------------------------------------------------------------
    # dump a ID3-v2 tag into a binary array
    #
    # NOTE:
    #      when "dumping" an ID3-v2 tag, I would like to have more control about
    #      which frames get dumped first.. e.g. the most important frames (with the
    #      most important information) should be dumped first.. 
    #
    
    public      
    def dump
      data = ""

      # dump all the frames
      self.each { |framename,framedata|
        data << framedata.dump
      }
      # add some padding perhaps 32 bytes (should be defined by the user!)
      # NOTE:    I noticed that iTunes adds excessive amounts of padding
      data << ZEROBYTE * 32
      
      # calculate the complete length of the data-section 
      size = mungeSize(data.size)
      
      major,minor = @version.sub(/^2\.([0-9])\.([0-9])/, '\1 \2').split
      
      # prepend a valid ID3-v2.x header to the data block
      header = "ID3" << major.to_i << minor.to_i << @rawflags << size[0] << size[1] << size[2] << size[3]
      
      header + data
    end
    # ----------------------------------------------------------------------

  end  # of class Tag2

end
