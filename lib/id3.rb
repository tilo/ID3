require 'awesome_print'

$:.unshift Dir.pwd
puts "Load Path is: "
ap $:


require 'tempfile'
require 'active_support'       # we'll borrow OrdreedHash from here.. no need to reinvent the wheel

# require 'id3/helpers/invert_hash'
# require 'id3/helpers/hexdump'

# # ==============================================================================
# # Extensions to standard Ruby classes:
# # ==============================================================================
# class Hash
#   # original Hash#invert is still available as Hash#old_invert
#   alias old_invert invert
  
#   # monkey-patching Hash#invert method - it's backwards compatible, but preserves duplicate values in the hash
#   def invert
#     self.inverse
#   end
# end

require 'id3/id3'

# require 'id3/constants.rb'
# require 'id3/module_methods'

# module ID3
  
#   autoload :AudioFile , 'id3/audio_file.rb'
#   autoload :GenericTag, 'id3/tag_generic.rb'
#   autoload :Tag1      , 'id3/tag1.rb'
#   autoload :Tag2      , 'id3/tag2.rb'
#   autoload :Frame     , 'id3/frame.rb'

# end
