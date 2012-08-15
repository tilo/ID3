
require 'tempfile'
require 'active_support'       # we'll borrow OrdreedHash from here.. no need to reinvent the wheel


require 'helpers/ruby_1.8_1.9_compatibility'  # define helper methods, so that we have the same interface for Ruby 1.8 and 1.9

require 'helpers/hash_extensions'   # loads Hash#inverse and overloads Hash#invert
require 'helpers/restricted_ordered_hash'  # derived from OrderedHash; used throughout ID3 library

# load hexdump method to extend class String
require "helpers/hexdump"           # only needed for debugging -> autoload

require 'id3/string_extensions'     # adds ID3 methods to String
require 'id3/io_extensions'         # adds ID3 methods to IO and File

require 'id3/version'               # Gem Version
require 'id3/constants'             # Constants used throughout the code
require 'id3/module_methods'        # add ID3 methods to ID3 which operate on filenames

require 'id3/audiofile'             # Higher-Level access to Audio Files with ID3 tags


require 'id3/generic_tag'
require 'id3/tag1'                  # ID3v1 tag class
require 'id3/tag2'                  # ID3v2 tag class
require 'id3/frame'                 # ID3v2 frame class
require 'id3/frame_array'           # Array extension for arrays of ID3::Frame s


# module ID3
  
#   autoload :AudioFile , 'id3/audio_file.rb'
#   autoload :GenericTag, 'id3/tag_generic.rb'
#   autoload :Tag1      , 'id3/tag1.rb'
#   autoload :Tag2      , 'id3/tag2.rb'
#   autoload :Frame     , 'id3/frame.rb'

# end
