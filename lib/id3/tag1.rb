module ID3

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

    def read(filename)
      f = File.open(filename, 'r')
      f.seek(-ID3::ID3v1tagSize, IO::SEEK_END)
      hastag = (f.read(3) == 'TAG')
      if hastag
        f.seek(-ID3::ID3v1tagSize, IO::SEEK_END)
        @raw = f.read(ID3::ID3v1tagSize)

        #           self.parse!(raw)    # we should use "parse!" instead of duplicating code!

        if (raw.getbyte(ID3v1versionbyte) == 0) 
          @version = "1.0"
        else
          @version = "1.1"
        end
      else
        @raw = @version = nil
      end
      f.close
      #
      # now parse all the fields

      ID3::SUPPORTED_SYMBOLS[@version].each{ |key,val|
        if val.class == Range
          #               self[key] = @raw[val].squeeze(" \000").chomp(" ").chomp("\000")
          self[key] = @raw[val].strip
        elsif val.class == Fixnum
          self[key] = @raw.getbyte(val).to_s
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
    
    # not yet implemented, because AudioFile.write does the job better
    
    # ----------------------------------------------------------------------
    # this routine modifies self, e.g. the Tag1 object
    #
    # tag.parse!(raw)   returns boolean value, showing if parsing was successful
    
    def parse!(raw)

      return false    if raw.size != ID3::ID3v1tagSize

      if (raw[ID3v1versionbyte] == 0) 
        @version = "1.0"
      else
        @version = "1.1"
      end

      self.clear    # remove all entries from Hash, we don't want left-overs..

      ID3::SUPPORTED_SYMBOLS[@version].each{ |key,val|
        if val.class == Range
          #               self[key] = raw[val].squeeze(" \000").chomp(" ").chomp("\000")
          self[key] = raw[val].strip
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
    # are often truncated and hence ID3 v1 tags are often useless..
    
    def dump
      zeroes = ZEROBYTE * 32
      raw = ZEROBYTE * ID3::ID3v1tagSize
      raw[0..2] = 'TAG'

      self.each{ |key,value|

        range = ID3::Symbol2framename['1.1'][key]

        if range.class == Range 
          length = range.last - range.first + 1
          paddedstring = value + zeroes
          raw[range] = paddedstring[0..length-1]
        elsif range.class == Fixnum
          raw[range] = value.to_i.chr      # supposedly assigning a binary integer value to the location in the string
        else
          # this can't happen the way we defined the hash..
          next
        end
      }

      return raw
    end
    # ----------------------------------------------------------------------
  end  # of class Tag1
  
end
