#!/usr/bin/ruby

# this script collects statistical output about ID3 collection
#

require "id3"


# ------------------------------------------------------------------------------
# recursiveDirectoryDescend
#      do action for files matching regexp
#
#      could be extended to array of (regexp,action) pairs
#
def recursiveDirectoryDescend(dir,regexp,action)
 # print "dir : #{dir}\n"

  olddir = Dir.pwd
  dirp = Dir.open(dir)
  Dir.chdir(dir)
  pwd = Dir.pwd
  @@dirN += 1

  for file in dirp
    file.chomp
    next if file =~ /^\.\.?$/

    fullname = "#{pwd}/#{file}"

    if File::directory?(fullname)
       recursiveDirectoryDescend(fullname,regexp,action)
    else
       @@fileN += 1
       if file =~ regexp
           # evaluate action
           eval action
       end
    end
  end
  Dir.chdir(olddir)
end
# ------------------------------------------------------------------------------

def eachSong(filename)
  filename.chomp!
  print "MP3-FILE: #{filename}"
  @@mp3fileN += 1

  if (File.size(filename) == 0)
    puts " -- empty file\n"
    return
  end

  v = 0
  tagN = 0

  v = ID3::hasID3v1tag?(filename)
  if v 
    print " -- found ID3-tag version #{v}"
    @@id3versionN[v] += 1
    tagN += 1
  end

  v = ID3::hasID3v2tag?(filename)
  if v 
    print " -- found ID3-tag version #{v}"
    @@id3versionN[v] += 1
    tagN += 1

    tag2= ID3::Tag2.new
    tag2.read(filename)

    size = tag2.raw.size
    @@sizeSum += size
    @@sizeMax = size if size > @@sizeMax
    printf "\ntag-size: %d , tag-keys: %s\n", size, tag2.keys.join(',')

    
    tag2.keys.each { |field|
        @@fieldsUsedN[tag2.version][field] += 1
    }
  end
  if tagN == 0
    print " -- no ID3-tag"
  end
  @@tagsPerFileN[tagN] += 1
  puts "\n"
end
# ------------------------------------------------------------------------------


@@fileN = 0
@@mp3fileN = 0
@@dirN  = 0
@@id3versionN = Hash.new(0)

@@fieldsUsedN = Hash.new
@@fieldsUsedN["1.0"] = Hash.new(0)
@@fieldsUsedN["1.1"] = Hash.new(0)
@@fieldsUsedN["2.2.0"] = Hash.new(0)
@@fieldsUsedN["2.3.0"] = Hash.new(0)
@@fieldsUsedN["2.4.0"] = Hash.new(0)

@@sizeMax = 0
@@sizeSum = 0


@@tagsPerFileN= Array.new(3,0)

dir = ARGV[0]

recursiveDirectoryDescend(dir, /.*\.[mM][pP]3/, %q{ eachSong(fullname) } )


print "

Files checked      : #{@@fileN}
Directories checked: #{@@dirN}

MP3 Files found  : #{@@mp3fileN}
"

version2tagN = 0

@@id3versionN.keys.each { |v|
  printf "\nnumber of ID3 tags v#{v} : #{@@id3versionN[v]}\n"
  version2tagN += 1 if v =~ /^2\./
}

puts "\n"

@@tagsPerFileN.each_index{ |x|
  printf "\nFiles tagged #{x}-times : #{@@tagsPerFileN[x]}\n"
}

ID3::SUPPORTED_SYMBOLS.keys.sort.each{ |v|

  puts "\nFIELDS USED IN VERSION #{v}\n"

  @@fieldsUsedN[v].keys.each { |field|
     printf "\t%20s : %d\n", field, @@fieldsUsedN[v][field]
  }

}

printf "\nMax v2 Tag Size was: %d , Average Tag Size was: %d\n" , @@sizeMax, (@@sizeSum / version2tagN)
puts "\n\ndone."
