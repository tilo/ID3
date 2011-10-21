# ----------------------------------------------------------------------------
# Module ID3 - MODULE METHODS
# ----------------------------------------------------------------------------
module ID3

  # The ID3 module methods are to query or modify files directly by filename.
  # They check directly if a file has a ID3-tag, but they don't parse the tags!
  
  # ----------------------------------------------------------------------------
  # id3_versions
  
  def ID3.id3_versions
    [ hasID3v1tag?(filename) ,hasID3v2tag?(filename) ].compact    # returns Array of ID3 tag versions found
  end
  
  # ----------------------------------------------------------------------------
  # hasID3v1tag? 
  #              returns string with version 1.0 or 1.1 if tag was found 
  #              returns false  otherwise

  def ID3.hasID3v1tag?(filename)
    hasID3v1tag     = false
    
    # be careful with empty or corrupt files..
    return false if File.size(filename) < ID3v1tagSize
    
    f = File.open(filename, 'rb:binary')
    f.seek(-ID3v1tagSize, IO::SEEK_END)
    if (f.read(3) == "TAG")
      f.seek(-ID3v1tagSize + ID3v1versionbyte, IO::SEEK_END)
      c = f.get_byte                         # this is character 125 of the tag
      if (c == 0) 
        hasID3v1tag = "1.0"
      else
        hasID3v1tag = "1.1"
      end
    end
    f.close
    return hasID3v1tag
  end
  
  # ----------------------------------------------------------------------------
  # hasID3v2tag? 
  #              returns string with version 2.2.0, 2.3.0 or 2.4.0 if tag found
  #              returns false  otherwise
  
  def ID3.hasID3v2tag?(filename)
    hasID3v2tag     = false
    
    f = File.open(filename, 'rb:binary')
    if (f.read(3) == "ID3")
      major = f.get_byte
      minor = f.get_byte
      version   = "2." + major.to_s + '.' + minor.to_s
      hasID3v2tag = version
    end
    f.close
    return hasID3v2tag
  end
  
  # ----------------------------------------------------------------------------
  # hasID3tag? 
  #              returns string with all versions found, space separated
  #              returns false  otherwise

  def ID3.hasID3tag?(filename)
    v1 = ID3.hasID3v1tag?(filename)
    v2 = ID3.hasID3v2tag?(filename)
    
    return false if !v1 && !v2 
    return v1    if !v2
    return v2    if !v1
    return "#{v1} #{v2}"
  end

  # ----------------------------------------------------------------------------
  # removeID3v1tag
  #            returns  nil  if no v1 tag was found, or it couldn't be removed
  #            returns  true if v1 tag found and it was removed..
  #
  # in the future:
  #            returns  ID3.Tag1  object if a v1 tag was found and removed

  def ID3.removeID3v1tag(filename)
    stat = File.stat(filename)
    if stat.file? && stat.writable? && ID3.hasID3v1tag?(filename)
      
      # CAREFUL: this does not check if there really is a valid tag,
      #          that's why we need to check above!!
      
      newsize = stat.size - ID3v1tagSize
      File.open(filename, "r+") { |f| f.truncate(newsize) }
      
      return true
    else
      return nil
    end
  end

  # ----------------------------------------------------------------------
  # convert the 4 bytes found in the id3v2 header and return the size
  def ID3.unmungeSize(bytes)
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
  def ID3.mungeSize(size)
    bytes = Array.new(4,0)
    j = 0;  i = 3
    while i >= 0
      bytes[j],size = size.divmod(128**i)
      j += 1
      i -= 1
    end
    return bytes
  end

end
# ----------------------------------------------------------------------------

