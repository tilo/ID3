#
# EXTENSIONS to Class IO (included in File)
#

# if you have a (partial) MP3-file stored in a File or IO object, you can check if it contains ID3 tags
# NOTE: file needs to be opened in binary mode! 'rb:binary'

class IO
  def id3_versions
    [ hasID3v1tag? ,hasID3v2tag? ].compact  # returns an Array of version numbers
  end
  
  def hasID3tag?
    hasID3v2tag? || hasID3v1tag? ? true : false         # returns true or false
  end
  
  def hasID3v1tag?
    seek(-ID3::ID3v1tagSize, IO::SEEK_END)
    if (read(3) == 'TAG')
      seek(-ID3::ID3v1tagSize + ID3::ID3v1versionbyte, IO::SEEK_END)
      return get_byte == 0 ? "1.0" : "1.1"
    else
      return nil
    end
  end
  
  def ID3v2_tag_size
    rewind
    return 0 if (read(3) != 'ID3')
    read_bytes(3)  # skip version and flags
    return ID3::ID3v2headerSize + ID3.unmungeSize( read_bytes(4) )
  end
  
  def hasID3v2tag?
    rewind
    if (read(3) == "ID3")
      major = get_byte
      minor = get_byte
      return version   = "2." + major.to_s + '.' + minor.to_s
    else
      return nil
    end
  end
end
