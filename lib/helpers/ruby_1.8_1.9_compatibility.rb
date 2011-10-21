# ==============================================================================
# Loading Libraries and Stuff needed for Ruby 1.9 vs 1.8 Compatibility
# ==============================================================================
# the idea here is to define a couple of go-between methods for different classes
# which are differently defined depending on which Ruby version it is -- thereby
# abstracting from the particular Ruby version's API of those classes

if RUBY_VERSION >= "1.9.0"
  require "digest/md5"
  require "digest/sha1"
  include Digest
  
  require 'fileutils'        # replaces ftools
  include FileUtils::Verbose
  
  class File
    def read_bytes(n)  # returns a string containing bytes
      #      self.read(n)
      #      self.sysread(n)
      self.bytes.take(n)
    end
    def write_bytes(bytes)
      self.syswrite(bytes)
    end
    def get_byte
      self.getbyte     # returns a number 0..255
    end
  end
  
  ZEROBYTE = "\x00".force_encoding(Encoding::BINARY) unless defined? ZEROBYTE
  
else # older Ruby versions:
  require 'rubygems'
  
  require "md5"
  require "sha1"
  
  require 'ftools'
  def move(a,b)
    File.move(a,b)
  end
  
  class String
    def getbyte(x)   # when accessing a string and selecting x-th byte to do calculations , as defined in Ruby 1.9
      self[x]  # returns an integer
    end
  end
  
  class File
    def read_bytes(n)
      self.read(n)   # should use sysread here as well?
    end
    def write_bytes(bytes)
      self.write(bytes)   # should use syswrite here as well?
    end
    def get_byte     # in older Ruby versions <1.9 getc returned a byte, e.g. a number 0..255
      self.getc   # returns a number 0..255
    end
  end
  
  ZEROBYTE = "\0" unless defined? ZEROBYTE
end
