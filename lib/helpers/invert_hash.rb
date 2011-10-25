# ==============================================================================
# EXTENDING CLASS HASH
# ==============================================================================
#--
# (C) Copyright 2004 by Tilo Sloboda <tools@unixgods.org>
#
# updated:  Time-stamp: <Mon, 24 Oct 2011, 23:03:29 PDT  tilo>
#
# License:
#         Freely available under the terms of the OpenSource "Artistic License"
#         in combination with the Addendum A (below)
#
#         In case you did not get a copy of the license along with the software,
#         it is also available at:   http://www.unixgods.org/~tilo/artistic-license.html
#
# Addendum A:
#         THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU!
#         SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
#         REPAIR OR CORRECTION.
#
#         IN NO EVENT WILL THE COPYRIGHT HOLDERS  BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL,
#         SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY
#         TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED
#         INACCURATE OR USELESS OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM
#         TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF THE COPYRIGHT HOLDERS OR OTHER PARTY HAS BEEN
#         ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
#++
# ==============================================================================

# Project Homepage:  http://www.unixgods.org/~tilo/Ruby/invert_hash.html
#
# This also appears in the "Facets of Ruby" library, and is mentioned in the O'Reilly Ruby Cookbook 
#
# Ruby's Hash.invert method can't handle the common case that two or more hash entries have the same value.
#
#  hash.invert.invert == h    # => ?       # is not generally true for Ruby's standard Hash#invert method
#
#  hash.inverse.inverse == h  # => true    # is true, even if the hash has duplicate values
#
# If you have a Math background, you would expect that performing an "invert" operation twice would result in the original hash.
#
# The Hash#inverse method provides this.
#
#
# If you want to permanently overload Ruby's original invert method, you may want to do this:
#
#  class Hash
#    alias old_invert invert   # old Hash#invert is still accessible as Hash#old_invert
#    
#    def invert
#      self.inverse            # Hash#invert is not using inverse method
#    end
#  end

class Hash
  
  # Returns a new hash, using given hash's values as keys and using keys as values.
  # If the input hash has duplicate values, the resulting hash will contain arrays as values.
  # If you perform inverse twice, the output is identical to the original hash.
  # e.g. no data is lost.
  #  
  #  hash = { 'zero' => 0 , 'one' => 1, 'two' => 2, 'three' => 3 ,   # English numbers
  #           'null' => 0, 'eins' => 1, 'zwei' => 2 , 'drei' => 3 }  # German numbers
  #  
  #  # Hash#inverse keeps track of duplicates, and preserves the input data
  #  
  #  hash.inverse          # => { 0=>["null", "zero"], 1=>["eins", "one"], 2=>["zwei", "two"], 3=>["drei", "three"] }
  #  
  #  hash.inverse.inverse  # => { "null"=>0, "zero"=>0, "eins"=>1, "one"=>1, "zwei"=>2, "two"=>2, "drei"=>3, "three"=>3 }
  #  
  #  hash.inverse.inverse == hash  # => true   # works as you'd expect
  #  
  #  # In Comparison:
  #  # 
  #  # the standard Hash#invert loses data when dupclicate values are present
  #  
  #  hash.invert           # => { 0=>"null", 1=>"eins", 2=>"zwei", 3=>"drei" }
  #  hash.invert.invert    # => { "null"=>0, "eins"=>1, "zwei"=>2, "drei"=>3 }   # data is lost
  #  
  #  hash.invert.invert == hash   # => false   # oops, data was lost!
  #   

  def inverse
    i = Hash.new
    self.each_pair{ |k,v|
      if (v.class == Array)
        v.each{ |x|
          if i.has_key?(x)
            i[x] = [k,i[x]].flatten
          else
            i[x] = k
          end
        }
      else
        if i.has_key?(v)
		   i[v] = [k,i[v]].flatten
        else
          i[v] = k
        end
      end
    }
    return i
  end
  
end


#--
# 
# require 'active_support'
# 
# class Hash
# 
#   def inverse
#     i = ActiveSupport::OrderedHash.new
#     self.each_pair{ |k,v|
#       if (v.class == Array)
#         v.each{ |x|
#           i[x] = i.has_key?(x) ? [i[x],k].flatten : k
#         }
#       else
#         i[v] = i.has_key?(v) ? [i[v],k].flatten : k
#       end
#     }
#     return i
#   end
# 
# end
