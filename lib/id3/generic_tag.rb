module ID3

  # ==============================================================================
  # Class GenericTag
  #
  # Helper class for Tag1 and Tag2
  #
  # Checks that user uses a valid key, and adds methods for size computation
  #
  # as per ID3-definition, the frames are in no fixed order! that's why we can derive
  # this class from Hash.  But in the future we may want to write certain frames first 
  # into the ID3-tag and therefore may want to derive it from RestrictedOrderedHash

  # BUG (4) : When an ID3frame is assigned a value, e.g. a String, then the Hash just stores the value right now.
  #           Whereas when you read the ID3v2 tag, the object for the frame is ID3::Frame

  class GenericTag < RestrictedOrderedHash
    attr_reader :version, :raw

    # these definitions are to prevent users from inventing their own field names..
    # but on the other hand, they should be able to create a new valid field, if
    # it's not yet in the current tag, but it's valid for that ID3-version...
    
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
            "               valid ID3-fields are: " + SUPPORTED_SYMBOLS[@version].keys.join(",") +"\n"
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
        size += 128**i * (bytes.getbyte(j) & 0x7f)
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

end # of module ID3
