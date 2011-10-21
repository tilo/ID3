#
# EXTENSIONS to Class Hash
#

# include Hash#inverse from Facets of Ruby or from our helper
# then Monkey-Patch the Hash#invert method:

require 'invert_hash'

class Hash
  # original Hash#invert is still available as Hash#old_invert
  alias old_invert invert
  
  # monkey-patching Hash#invert method - it's backwards compatible, but preserves duplicate values in the hash
  def invert
    self.inverse
  end
end


