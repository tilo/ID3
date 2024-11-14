# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "id3/version"

spec = Gem::Specification.new do |s|
  s.name = 'id3'
  s.version = ID3::VERSION
  s.authors = ['Tilo Sloboda']
  s.email  = ['tilo.sloboda@gmail.com']
  s.homepage = 'http://www.unixgods.org/~tilo/Ruby/ID3'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A native ID3 tag library for Ruby, which does not depend on architecture-dependent C-libraries. It supports reading and writing ID3-tag versions 1.0, 1.1, and 2.2.x, 2,3.x, 2,4.x\n http://www.unixgods.org/~tilo/Ruby/ID3'
  s.description = 'ID3 is a native ruby library for reading and writing ID3 tag versions 1.0, 1.1, and 2.2.x, 2,3.x, 2,4.x'

 s.files         = `git ls-files`.split("\n")
#  s.files = Dir['docs/**/*'] + Dir['lib/*.rb'] + Dir['lib/id3/*.rb']  + Dir['lib/helpers/*.rb'] + ['LICENSE.html' , 'index.html',  'README.md' , 'CHANGES']
#  s.test_files = FileList["{tests}/**/*test.rb"].to_a
  s.has_rdoc = false
  s.require_paths = ['lib']
  s.autorequire = 'id3'
#  s.extra_rdoc_files = ['README']
  s.rdoc_options << '--title' <<  'Native ID3 Ruby Library - uniform acecss to ID3v1 and ID3v2 tags'
  s.add_dependency("activesupport", ">= 5")
#  s.add_dependency("dependency", ">= 0.9.9")
#  s.bindir = 'bin'

  s.rubyforge_project = 'id3'
#  s.rubyforge_project = ['none']
end

#Rake::GemPackageTask.new(spec) do |pkg|
#  pkg.need_tar = true
#end
