#
# EXTENSIONS to Class String
#
# if you have a (partial) MP3-file stored in a String.. you can check if it contains ID3 tags

class String
  # str = File.open(filename, 'rb:binary').read; 1
  # str.hasID3v2tag?
  # str.hasID3v1tag?
  
  def id3_versions
    [ hasID3v1tag? ,hasID3v2tag? ].compact   # returns an Array of version numbers
  end

  def hasID3tag?
    hasID3v2tag? || hasID3v1tag? ? true : false     # returns true or false
  end
  
  def hasID3v2tag?  # returns either nil or the version number -- this can be used in a boolean comparison
    return nil if self !~ /^ID3/
    major = self.getbyte(ID3::ID3v2major)
    minor = self.getbyte(ID3::ID3v2minor)
    version   = "2." + major.to_s + '.' + minor.to_s
  end
  
  # we also need a method to return the size of the ID3v2 tag , 
  # e.g. needed when we need to determine the buffersize to read the tag from a file or from a remote location
  def ID3v2_tag_size
    return 0 if self !~ /^ID3/
    return ID3::ID3v2headerSize + ID3.unmungeSize( self[ID3::ID3v2tagSize..ID3::ID3v2tagSize+4] )
  end

  def hasID3v1tag?  # returns either nil or the version number -- this can be used in a boolean comparison
    return nil if size < ID3::ID3v1tagSize  # if the String is too small to contain a tag
    size = self.bytesize
    tag = self[size-128,size] # get the last 128 bytes
    return nil if tag !~/^TAG/
    return tag[ID3::ID3v1versionbyte] == ZEROBYTE ? "1.0" : "1.1"   # return version number otherwise
  end
end
