# ==============================================================================
# Class RestrictedOrderedHash
#    this is a helper Class for ID3::Frame
#
#    this is a helper Class for GenericTag
#
#    this is from 2002 .. new Ruby Versions now have "OrderedHash" .. but I'll keep this class for now.

class RestrictedOrderedHash < ActiveSupport::OrderedHash

  attr_accessor :locked
  
  def lock
    @locked = true
  end
  
  def initialize 
    @locked = false
    super
  end
  
 alias old_store []=

  def []= (key,val)
    if self[key]
      #            self.old_store(key,val)    # this would overwrite the old_value if a key already exists (duplicate ID3-Frames)
      
      # strictly speaking, we only need this for the ID3v2 Tag class Tag2:
      if self[key].class != FrameArray   # Make this ID3::FrameArray < Array
        old_value = self[key]
        new_value = FrameArray.new
        new_value << old_value           # make old_value a FrameArray
        self.old_store(key, new_value  )
      end
      self[key] << val
      
    else
      if @locked
        # we're not allowed to add new keys!
        raise ArgumentError, "You can not add new keys! The ID3-frame #{@name} has fixed entries!\n" +
          "               valid key are: " + self.keys.join(",") +"\n"
      else 
        self.old_store(key,val)
      end
    end
  end
  
  # users can not delete entries from a locked hash..
  
  alias old_delete delete
  
  def delete(key)
    if !@locked
      old_delete(key)
    end
  end
end


# ==============================================================================
# Class RestrictedOrderedHashWithMultipleValues
#    this is a helper Class for ID3::Frame
# 
# same as the parent class, but if a key is already present, it stores multiple values as an Array of values

# class RestrictedOrderedHashWithMultipleValues < RestrictedOrderedHash
#   alias old_store2 []=

#   # if key already in Hash, then replace value with [ old_value ] and append new value to it.
#   def []= (key,val)

#     puts "Key: #{key} , Val: #{val} , Class: #{self[key].class}"

#     if self[key]
#       if self[key].class == ID3::Frame
#         old_value = self[key]
#         self[key] = [ old_value ]
#       end
#       self[key] << value
#     else
#       self.old_store2(key,val)
#     end
#   end

# end

