module ID3
  # ==============================================================================
  # Class FrameArray
  # 
  # basically nothing more than an Array, but it knows how to dump it's contents as ID3v2 frames
  #
  # this solves in part the problem of having multiple ID3v2 frames in one tag, e.g. TXXX , WXXX, APIC

  class FrameArray < Array
    def dump
      result = ''
      self.each do |element|
        result << element.dump
      end
      return result
    end
  end

end
