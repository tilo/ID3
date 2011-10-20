
# ------------------------------------------------------------------------------
# SOME EXAMPLES on how the library is intended to be used
# ------------------------------------------------------------------------------

# EXAMPLE of stripping extra v1-tag if v2-tag is present:

file = "bla.mp3"
if ID3::has_id3_tag?( file )
   myfile = AudioFile.open( file )        # do we need a new here?
   
   # if a file has both tags (v1 and v2), we delete the v1 tag:
   if (myfile.has_id3v1_tag?) && (myfile.has_id3v2_tag?)
      myfile.id3v1tag = nil
      myfile.write              # we only write if we modified it..
   end
end

# NOTE:   may use   id3v1tag.clear   or   id3v1tag = {}  instead

# ------------------------------------------------------------------------------

# EXAMPLE of stripping attached pictures from id3v2-tags if present, 
#         and re-setting the play counter to 0
#         and setting the comment to something silly

file = "bla.mp3"
if ID3::has_id3v2_tag?( file )
   myfile = AudioFile.open( file )        # do we need a new here?
#   if (myfile.id3v2tag.member?(PICTURE))  # if there is a picture in the tag..
      myfile.id3v2tag.delete(PICTURE)     # deletes the unwanted picture..
#   end
   myfile.id3v2tag["PLAYCOUNTER"] = 0     # reset the play counter to 0
   myfile.id3v2tag["COMMENT"] = "Tilo's MP3 collection"   # set the comment
   
   myfile.id3v2tag.options["PADDINGSIZE"] = 0        # shrink the tag!
   myfile.id3v2tag.options["APPENDTAG"]   = false    # shrink the tag!
   myfile.id3v2tag.options["FOOTER"]      = false    # shrink the tag!
   myfile.id3v2tag.options["EXT_HEADER"]  = false    # shrink the tag!
   
   myfile.write   # writes to the same filename, overwriting the old file
   myfile.write("new.mp3")   # creates new file
   myfile.close
end

# ------------------------------------------------------------------------------

# CODE FRAGMENT   from initialization of AudioFile

# when we open a file and create a new ID3-tag, we should do this internally:

   v1 = ID3::has_id3v1_tag?( file )
   v2 = ID3::has_id3v2_tag?( file )       # but may not be a version we know
                                          # about...
   
   if (v2)                                # if version is not nil
      id3v2tag = ID3v2tag.new( v2 )       # only create tag if one in file
   end 
   
   if (v1)
      id3v1tag = ID3v1tag.new( v1 )       # only create tag if one in file
   end 

# or we do it the same way as in the old library:

   v1 = ID3::has_id3v1_tag?( file )
   v2 = ID3::has_id3v2_tag?( file )

   id3v2tag = ID3v2tag.new( v2 ) 
   id3v2tag.read_v2(file)
   
   
# similarly, when creating a new frame, we need to read it first, 
# before we can create the correct instance with the correct singleton
# methods...

   frame = Frame.new  # should create a new frame of the correct type..
   
# ------------------------------------------------------------------------------




   
------------------------------------------------------------------------------

# EXAMPLE tagging an existing MP3 track..

file = "reeeee.mp3"


if ! ID3::has_id3v2_tag?( file )        # if there is no v2 tag 

   myfile = AudioFile.open( file )        # do we need a new here?
   
   newtag = ID3v2tag("2.3.0")             # create a new,empty v2 tag
   newtag["TITLE"] = "Reeeee!"
   newtag["ARTIST"] = "Dan Mosedale"
   newtag["LYRICIST"] = "Dan Mosedale"
   newtag["COMPOSER"] = "Dan Mosedale"
   newtag["LANGUAGE"] = "Monkey"          # should raise an error, because there is no 
                                          # ISO language code for "Monkey"
                                          
   newtag["BAND"] = "Mozilla and the Butt Monkeys"
   newtag["TRACKNUM"] = 1                 # will be converted to "1"
   newtag["DATE"] = "2000/05/02"          # will be converted to correct date format
   
   newtag["COMMENT"] = "The sound which monkeys make when they are flying out of someones butt.."
   
   newtag.options["PADDINGSIZE"] = 0

   myfile.id3v2tag = newtag         # assoziate the new tag with the AudioFile..
                                    # NOTE: we should CHECK when assigning a tag, 
                                    #       that the version number matches!

   myfile.write(file)               # if we overwrite, we should save the old tag in "filename.oldtag"
   myfile.close
end      
------------------------------------------------------------------------------

# EXAMPLE to convert a file from older id3v2.x tags to id3v2.3 tags

file = "bla.mp3"
if ID3::has_id3v2_tag?( file )
   myfile = AudioFile.open( file )        # do we need a new here?
   
   if (myfile.id3v2tag.version < "2.3.0")

   
       newtag = ID3v2tag("2.3.0")
       
#       newtag = ID3v2tag.new              # create new empty tag 
#       newtag.version = "2.3.0"           # of specific version

       myfile.id3v2tag.each { |key, value|
           newtag[key] = value
       }
       myfile.id3v2tag = newtag

       myfile.id3v2tag.options["PADDINGSIZE"] = 0      # shrink the tag!

       myfile.write   # writes to the same filename, overwriting the old file
       myfile.write("new.mp3")   # creates new file
       
   end
   
   myfile.close
end

------------------------------------------------------------------------------

# EXAMPLE to check if two tags are equivalent.. e.g. if they contain the 
#         same fields with the same values..

ID3::tags_equivalent(other)

# we also need to check if the number of keys is the same in each hash

equivalent = true
self.each { |key,value| 
   equivalent = false   if self[key] != other[key]
}
return equivalent

------------------------------------------------------------------------------
