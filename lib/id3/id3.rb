################################################################################
# id3.rb  Ruby Module for handling the following ID3-tag versions:
#         ID3v1.0 , ID3v1.1,  ID3v2.2.0, ID3v2.3.0, ID3v2.4.0
# 
# Copyright (C) 2002 .. 2011 by Tilo Sloboda <firstname.lastname@google_email>
#
# created:      12 Oct 2002
# updated:      Time-stamp: <Fri, 21 Oct 2011, 11:54:26 PDT  tilo>
#
# Docs:   http://www.id3.org/id3v2-00.txt
#         http://www.id3.org/id3v2.3.0.txt
#         http://www.id3.org/id3v2.4.0-changes.txt
#         http://www.id3.org/id3v2.4.0-structure.txt
#         http://www.id3.org/id3v2.4.0-frames.txt
#  
#         different versions of ID3 tags, support different fields.
#         See: http://www.unixgods.org/~tilo/Ruby/ID3/docs/ID3v2_frames_comparison.txt
#         See: http://www.unixgods.org/~tilo/Ruby/ID3/docs/ID3_comparison2.html
#
# PLEASE HELP:
#
#  >>>    Please contact me and email me the extracted ID3v2 tags, if you:
#  >>>      - if you have tags with exotic character encodings (exotic for me, not for you, obviously ;-) )
#  >>>      - if you find need support for any ID3v2 tags which are not yet supported by this library
#  >>>        (e.g. they are currently just parsed 'raw' and you need them fully parsed)
#  >>>      - if something terribly breaks
#  >>>   
#  >>>    You can find a small helper program in the examples folder, which extracts a ID3v2 tag from a file,
#  >>>    and saves it separately, so you can email it to me without emailing the whole audio file.
#  >>>
#  >>>    THANK YOU FOR YOUR HELP!
#
# Non-ASCII encoded Strings:
#
#   This library's main purpose is to unify access across different ID3-tag versions. So you don't have to worry
#   about the changing names of the frames in different ID3-versions, and e.g. just access "AUTHOR" symbolically
#   no matter if it's ID3 v1.0 v2.1.0 or v2.4.0.  Think of this as a low-level library in that sense.
#
#   Non-ASCII encodings are currently not really dealt with. For Strings which can be encoded differntly, 
#   you will see attributes like 'encoding' and 'text', where 'encoding' is a number representing the encoding,
#   and the other attribute, e.g. 'text' or 'description', is the raw uninterpreted String.
#
#   If your code requires to assign values to a ID3v2-frame which are foreign encoded Strings, you will need to make
#   a small wrapper class on top of ID3::Frame which detects the encoding and properly saves it as a number.
#   I'd love to add this -- but I don't have enough examples of ID3-tags in foreign languages. See: PLEASE HELP
#
# Limitations:
#
#   - this library currently does not support the ID3v2.4 feature of having ID3v2 tags at the end of the file
#     IMHO this doesn't make much sense in the age of streaming, and I haven't found examples for ths in any MP3-files. 
#     I think this is just one of the many unused "features" in the ID3v2 specifications ;-)
#
#   - ID3v2 Chapters are not supported (see: Wikipedia)
#
#   - ID3v1 extended tags are currently not supported (see: Wikipedia)
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
#
#
# Author's Rant:
#         The author of this ID3-library for Ruby is not responsible in any way for 
#         the awkward definition of the ID3-standards..
#
#         You're lucky though that you can use this little library, rather than having 
#         to parse ID3v2 tags yourself!  Trust me!  At the first glance it doesn't seem
#         to be so complicated, but the ID3v2 definitions are so convoluted and 
#         unnecessarily complicated, with so many useless frame-types, it's a pain to 
#         read the documents describing the ID3 V2.x standards.. with tiny bits of information
#         strewn all accross the documents here and there..  and even worse to implement them.
#
#         I don't know what these people were thinking... can we make it any more 
#         complicated than that??  ID3 version 2.4.0 tops everything!   If this flag
#         is set and it's a full moon, and an even weekday number, then do this.. 
#         Outch!!!  I assume that's why I don't find any 2.4.0 tags in any of my 
#         MP3-files... seems like noone is writing 2.4.0 tags... iTunes writes 2.3.0
#
################################################################################
# How does it work?
#
# Main concepts used:
#
#   - Unification of ID3 Frames according to this nomenclature, using "pretty" names for frames:
#         http://www.unixgods.org/~tilo/Ruby/ID3/docs/ID3_comparison2.html
#
#   - String pack/unpack to parse and dump contents of ID3v2 frames; 
#     For each ID3v2 frame type, there is a specific list of attributes for that frame 
#     and a pack/unpack recipe associated with that frame type (see: FRAME_PARSER Hash)
#
#   - if there is a ID3v2 frame that's not parsed yet, it's easy to add:
#     - create a new entry for that frame's symbolic (pretty) name in FRAMETYPE2FRAMENAME Hash
#     - make sure to delete that name from the "UNPARSED" category
#     - add an entry to FRAME_PARSER Hash
#     - note how these pre-defined Hashes are used in ID3::Frame class during parse() and dump()
#
#   - Metaprogramming: when ID3v2 frames are instanciated when they are read, 
#     we define parse and dump methods individually, using above pack/unpack recipes
#     (check the two lines which use  ID3::FRAME_PARSER to better understand the internal mechanics)
#
#  - After the ID3v2 frames are parsed, they are Hashes; the keys are the attributes defined in FRAME_PARSER, 
#    the values are the extracted data from the ID3v2 tag.
#
################################################################################
#--
# TO DO:
#
# - haven't touched the code in a very long time.. 
#   - I should write a general write-up and explanation on how to use the classes
#   - I should write a general write-up to explain the metaprogramming ;)
# 
# - they really changed all the IO calls in Ruby 1.9 -- how painful!!
#   I need to make some wrappers, to handle this nicely in both Ruby 1.9 and 1.8
#
# - should probably use IO#sysopen , IO#sysseek , IO#sysread , IO#syswrite for low-level i/o
# - files should be opened with the 'b' option - to tell Ruby 1.9 to open them in binary mode
#
# - Note: the external representation for non-printable characters in strings is now hex, not octal
# - should use sha1 instead of md5
# - some functionality , like has_id3...tag?  and is_mp3_file? should extend class File instead of being an ID3 module method
# - class AudioFile could extend class IO or File - hmm, not sure
# - class RestrictedOrderedHash vs OrderedHash vs Hash ...??   can we just do this with the ordered hash in 1.9?
#   should probably at least inherit RestrictedOrderedHash < ActiveSupport::OrderedHash
#
# - tripple-check if the semantics of pack/unpack has changed between 1.8 and 1.9
# - hexdump definitely barfs in Ruby 1.9 -- needs fixing
#
# - check out ruby-uuid on how he manipulates raw bytes.. looks like it is Ruby 1.9 compatible.. .ord .char .bytes
#
# - this needs some serious refactoring..
#++


# ==============================================================================



# ==============================================================================

module ID3

# ... moved everything into separate files    

end   # of module ID3
