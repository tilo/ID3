################################################################################
# id3v2.rb     Ruby Module for handling the following ID3-tag versions:
#                  ID3v1.0 , ID3v1.1,  ID3v2.2.0, ID3v2.3.0, ID3v2.4.0
# 
# Copyright:   Tilo Sloboda <tilo@unixgods.org> , created 12 October 2002
#
# Docs:   http://www.id3.org/id3v2-00.txt
#         http://www.id3.org/id3v2.3.0.txt
#         http://www.id3.org/id3v2.4.0-changes.txt
#         http://www.id3.org/id3v2.4.0-structure.txt
#         http://www.id3.org/id3v2.4.0-frames.txt
#
# License:     
#         Freely available under the terms of the OpenSource "Artistic License"
#         in combination with the Addendum A (below)
# 
#         In case you did not get a copy of the license along with the software, 
#         it is also available at:   http://www.unixgods.org/~tilo/replace_string/ 
#
# Addendum A: 
#         THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU!
#         SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
#         REPAIR OR CORRECTION. 
#
#         IN NO EVENT WILL THE COPYRIGHT HOLDERS  BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, 
#         SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY 
#         TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED 
#         INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM 
#         TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF THE COPYRIGHT HOLDERS OR OTHER PARTY HAS BEEN
#         ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
#
#-------------------------------------------------------------------------------
#  Module ID3
#
#    n = ID3.hastag?(filename)
#
#    ID3.field[SYMBOLIC_FIELD] = "value";
#
#    ID3.update
#
#   Class ID3tag
#      @version          ID3 version
#      @size             size of the tag
#      @seek             position in bytes where to find the tag.
#
#   Class ID3v1tag       (formerly class Mp3Tag )
#
#      new(filename)     .. calls readtag
#      commit
#      removetag
#      filename
#      readtag
#
#      @songname             songname     songname=
#      @artist               artist       artist=
#      @album                album        album=
#      @year                 year         year=
#      @comment              comment      comment=
#      @tracknum             tracknum     tracknum=
#      @genre_id             genre_id     genre_id=
#      @genre                genre        genre=
#
#   Class ID3v2tag
#
#      
#
#
#
#   Class ID3v2frame
#
#      - each frame knows what it's name is, what the size is, how to read/write itself,
#        and how to input/output parameters from/to the user, knows how to compute it's size
#        
#
#         TextFrame < Frame
#         BinaryFrame < Frame
#
#
#
#   - ideally the user should be able to use a high-level interface to just 
#     read/write/update a tag, without knowing the gory details
#
#   - advanced users should be able to use a lower level interface to have more control
#
################################################################################




=begin
= Synopsis

Parse for an existing ID3-tag and return it's version number

    version = ID3tag.hastag?(filename)

returns 0 if no ID3-tag was found, or the version number of the tag

=end

module ID3

  # check if file has a ID3-tag and which version it is
  # 
  # NOTE: file might be tagged twice! :(

  ID3v1tagSize = 128;    # ID3v1 and ID3v1.1 have fixed size tags at end of file

  def ID3::hastag?(filename)
    @hastag     = 0
    @id3version = ''
    
    File.open(filename, 'r') { |f|
      f.seek(-ID3v1tagSize, IO::SEEK_END)
      if (f.read(3) == "TAG")
         @hastag += 1
          ver = "1.0"
         @id3version == "" ? @id3version = ver : @id3version += " " + ver
      end
    }

    f = File.open(filename, 'r')
    if (f.read(3) == "ID3")
       major = f.getc
       minor = f.getc
       ver   = "2." + major.to_s + '.' + minor.to_s
       @id3version == "" ? @id3version = ver : @id3version += " " + ver

       @hastag += 1
    end
    f.close
    return @hastag
  end

  def version
     @id3version
  end

## -- Class ID3v1tag -------------------------------------------------------------

require "mp3tag"

class ID3v1tag < Mp3Tag 
        # Mp3Tag is by Lars Christensen <larsch@cs.auc.dk>
        # we just alias his class..  i didn't want to re-implement it. 
end


## -- Class ID3tag -------------------------------------------------------------

class ID3tag


  def initialize
 
      @hastag = FALSE
      @id3version = []

  end


## -------------------------------------------------------------------------------

def readN(f, n)
  x = 0
  for i in 1..n
    x +=  256**(n-i)*f.read(1)[0]
  end
  return x
end

  # ----------------------------------------------------------------------
  # convert the 4 bytes found in the id3v2 header and return the size

  def unmungeSize(bytes)
    size = 0
    j = 0; i = 3 
    while i >= 0
       size += 128**i * (bytes[j] & 0x7f)
       j += 1
       i -= 1
    end
    return size
  end
  # ----------------------------------------------------------------------
  # convert the size into 4 bytes to be written into an id3v2 header
  
  def mungeSize(size)
    bytes = Array.new(4,0)
    j = 0;  i = 3
    while i >= 0
      bytes[j],size = size.divmod(128**i)
      j += 1
      i -= 1
    end

    return bytes
  end
  # ----------------------------------------------------------------------
  #  data is a string containing the data  (NOT COMPLETELY FUNCTIONAL)

  def hexdump(data, offset=0)
     datasize = data.size
    
     chunks,rest = datasize.divmod(16)
     address = offset; i = 0 
     print "\n address     0 1 2 3  4 5 6 7  8 9 A B  C D E F\n\n"
     while i < chunks*16
        str = data[i..i+15]
        if str != "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
          str.tr!("\000-\037\177-\377",'.')
          printf( "%08x    %8s %8s %8s %8s    %s\n", 
                address, data[i..i+3].unpack('H8'), data[i+4..i+7].unpack('H8'),
                   data[i+8..i+11].unpack('H8'), data[i+12..i+15].unpack('H8'),
	       str)
	end
        i += 16; address += 16
     end
     j = i; k = 0
     printf( "%08x    ", address)
     while (i < datasize)
          printf "%02x", data[i]
          i += 1; k += 1
          print  " " if ((i % 4) == 0)
     end
     for i in (k..15)
            print "  "
     end
     str = data[j..datasize]
     str.tr!("\000-\037\177-\377",'.')
     printf ("     %s\n", str)
  end

  # ----------------------------------------------------------------------
  
  def read_tag(filename)
    f = File.open(filename, 'r')
    @header = Array.new(10,0)
    @header = f.read(10)
    f.seek(0)
    if (f.read(3) == "ID3")
       major = f.getc
       minor = f.getc
       id3version = major.to_s + '.' + minor.to_s
       flag = f.getc
       @datasize = size = unmungeSize(f.read(4))
       @data = Array.new(size,0)
       @data = f.read(size) 
    end
    f.close
  end

  # ----------------------------------------------------------------------
  # making data avaliable: 

  def header
      @header
  end

  def data
      @data
  end
  def datasize
      @datasize
  end
  def hastag
      @hastag
  end
  def id3version
      @id3version
  end

end 
#
## -- Class ID3tag ---------------------------------------------------------------



##### Class ID3frame #############################################################
# 
# ID3v2 frames implementation
#
#   - each frame consists of a header and a data section
#   - the header is of fixed size (it's size is depending on the ID3 version,)
#   - all frames in one ID3v2 header have the same size
#   - 
#
#
#
class ID3frame

  @header = ''
  @data = ''
  @size = 0
  @id3version = 0


  # INPUT  : filehandle, version
  # RETURNS: nil            if  filehandle points to "0" bytes
  #          frame object   if  frame header found
  #
  def initialize(data,version,offset=0)
    
#    if version =~ "1."
#        raise exception
        
     if version == "2.0"
        @headersize = 6
        @name = data[0..2]
        @size = (data[3]*256**2)+(data[2]*256)+data[3]
     else 
        @headersize = 10
        @name = data[0..3]
        @size = (data[4]*256**3)+(data[5]*256**2)+(data[6]*256)+data[7]
        @flags= data[8..9]
     end
     @data = data[@headersize..(@headersize + @size - 1)]
  end

  def data
     @data
  end
  def size
     @size
  end
  def id3version
     @id3version
  end
end 

## -------------------------------------------------------------------------------

end 

#   END of module ID3
##################################################################################
