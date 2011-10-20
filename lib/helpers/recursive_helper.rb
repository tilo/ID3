# module ID3
#  module Helpers

    # ------------------------------------------------------------------------------
    # recursiveDirectoryDescend
    #      do action for files matching regexp
    #
    #      could be extended to array of (regexp,action) pairs
    #
    def recursive_dir_descend(dir,regexp,action)
     # print "dir : #{dir}\n"

      olddir = Dir.pwd
      dirp = Dir.open(dir)
      Dir.chdir(dir)
      pwd = Dir.pwd
      @dirN += 1

      for file in dirp
        file.chomp
        next if file =~ /^\.\.?$/
        filename = "#{pwd}/#{file}"

        if File::directory?(filename)
           recursive_dir_descend(filename,regexp,action)
        else
           @fileN += 1
           if file =~ regexp
               # evaluate action
               eval action
           end
        end
      end
      Dir.chdir(olddir)
    end
    # ------------------------------------------------------------------------------

#  end
# end
