
require 'awesome_print'

require 'id3'


require '../helpers/recursive_helper'


# ------------------------------------------------------------------------------
def each_song(filename)
  filename.chomp!
  @mp3fileN += 1

#  puts "Filename: #{filename}"

  if File.size(filename) == 0
    @empty_fileN += 1
    puts "EMPTY MP3-File: #{filename}"   # better to know this, hum?
    return
  end

  mp3 = ID3::AudioFile.new(filename)   # CAN WE CALL THIS WITH A BLOCK??
  if mp3.id3_versions.empty?
    @no_id3_tagN += 1
    puts "NO ID3 TAGS: #{filename}"   # better to know this, hum?
    return
  else    
    mp3.id3_versions.each do |v|
      # count how often we saw a certain ID3 tag version
      @id3_versionNH[v] += 1

      if mp3.has_id3v2tag?
        # count how often we saw a certain ID3v2 tag size
        @id3v2_tag_sizesH[v][mp3.tagID3v2.raw.size] ||= 0
        @id3v2_tag_sizesH[v][mp3.tagID3v2.raw.size]  += 1

        # count how often we saw a certain ID3v2 tag
        mp3.tagID3v2.keys.each do |tag|
          @id3v2_fields_usedH[v][tag] ||= 0
          @id3v2_fields_usedH[v][tag]  += 1
        end
      else
        @only_id3v1_tagN += 1   # if a file only has a ID3v1 tag, we also need a warning message
        puts "ONLY ID3v1 TAG: #{filename}"   # better to know this, hum?
      end
    end
  end
end
# ------------------------------------------------------------------------------



mp3_library_dir = '~/Music/iTunes/iTunes Music'  # e.g. on a Mac

mp3_library_dir = '/Users/tilo/Music/iTunes/iTunes Music'

@dirN = 0
@fileN = 0
@mp3fileN = 0

@empty_fileN = 0
@no_id3_tagN = 0
@only_id3v1_tagN = 0

@id3v2_fields_usedH = {}
@id3v2_tag_sizesH   = {}
@id3_versionNH      = {}
ID3::VERSIONS.each do |v|
  @id3v2_fields_usedH[v] = {}
  @id3v2_tag_sizesH[v]   = {}
  @id3_versionNH[v]      = 0
end

# gather statistics on the ID3 tags used in your MP3 library:
recursive_dir_descend( mp3_library_dir , /.*.[mM][pP]3$/ ,   'each_song(filename)'); 1


print "
Files checked: #{@fileN}
Dirs checked:  #{@dirN}

MP3 Files found: #{@mp3fileN}

Empty MP3 Files: #{@empty_fileN}

NO ID3 Tag at all: #{@no_id3_tagN}

ONLY ID3v2 Tag:  #{@only_id3v1_tagN}

"

puts '--------------------'
ap @id3v2_fields_usedH ; 1
puts '--------------------'
ap @id3v2_tag_sizesH ;1 
puts '--------------------'
ap @id3_versionNH ;1
puts '--------------------'

print "
Files checked: #{@fileN}
Dirs checked:  #{@dirN}

MP3 Files found: #{@mp3fileN}

Empty MP3 Files: #{@empty_fileN}

NO ID3 Tag at all: #{@no_id3_tagN}

ONLY ID3v2 Tag:  #{@only_id3v1_tagN}

"

puts "\n\ndone."


exit



# ----- BAUSTELLE: --------------------

require 'active_support'


class Hash

  def inverse
    i = ActiveSupport::OrderedHash.new
    self.each_pair{ |k,v|
      if (v.class == Array)
        v.each{ |x|
          i[x] = i.has_key?(x) ? [i[x],k].flatten : k
        }
      else
        i[v] = i.has_key?(v) ? [i[v],k].flatten : k
      end
    }
    return i
  end

end
