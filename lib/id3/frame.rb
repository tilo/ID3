module ID3
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
  #
  # NOTE3:  
  #
  #         The old way to pack / unpack frames to encode / decode them, is working, 
  #         but has the disadvantage that it's a little bit too close to the metal.
  #         e.g. encoding and textcontent are both accessible, but ideally only 
  #         the textvalue should be accessible and settable, and the encoding should 
  #         automatically be set correctly / accordingly...
  #
  # NOTE4:
  #         for frames like TXXX , WXXX , which can occur multiple times in a ID3v2 frame,
  #         we should manage those tags as an Array...
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

    def initialize(name, version = '2.3.0', flags = 0, tag,  headerStartX, dataStartX, dataEndX )
      super

      @name = name
      @headerStartX = headerStartX if headerStartX
      @dataStartX   = dataStartX   if dataStartX
      @dataEndX     = dataEndX     if dataEndX

      if tag
        @rawdata   = tag.raw[dataStartX..dataEndX]
        @rawheader = tag.raw[headerStartX..dataStartX-1]
        # parse the darn flags, if there are any..
        @version = tag.version  # caching..
      else
        @rawdata = ''
        @rawheader= ''
        @version = version
      end

      case @version
      when /2\.2\.[0-9]/
        # no flags, no extra attributes necessary

      when /2\.[34]\.0/
        
        # dynamically create attributes and reader functions for flags in ID3-frames:
        # (not defined in earlier ID3 versions)
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
        
        FRAME_HEADER_FLAGS[@version].each do |key,val|
          # only define the flags which are set..
          @flags[key] = true   if  (flags.to_i & val == 1)
        end
        
      else
        raise ArgumentError, "ID3 version #{@version} not recognized when parsing frame header flags\n"
      end # parsing flags
                 
      # generate methods for parsing data (low-level read support) and for dumping data out (low-level write-support)
      #
      # based on the particular ID3-version and the ID3-frame name, we basically obtain a string saying how to pack/unpack the data for that frame
      # then we use that packing-string to define a parser and dump method for this particular frame
                 
      instance_eval <<-EOB
        class << self

          def parse
            # here we GENERATE the code to parse, dump and verify  methods
          
            vars,packing = ID3::FRAME_PARSER[ ID3::FrameName2FrameType[ ID3::Framename2symbol[self.version][self.name]] ]

            values = self.rawdata.unpack(packing)

            vars.each do |key|
              self[key] = values.shift
            end
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
        
      return self
    end
    # ----------------------------------------------------------------------
            
  end  # of class Frame
  # ==============================================================================

end
