
require 'id3'

tag1 = ID3::Tag1.new
tag1.read('mp3/d.mp3')

tag2 = ID3::Tag1.new
tag2.read('mp3/a.mp3')

raw = tag1.dump
raw.hexdump
tag1.raw.hexdump

t =  ID3::Tag1.new
v,h = t.parse!(raw)


raw = tag2.dump
raw.hexdump
v,h = t.parse!(raw)


t['BLA'] = "blubb"

# -------------------------------------------------------------------------------- 

 require 'id3'

 t = ID3::Tag2.new
 t.read("mp3/d.mp3")
 t["ARTIST"]

  t["ARTIST"].dump.hexdump

   t.delete('PICTURE')
   t.dump.hexdump

# -------------------------------------------------------------------------------- 

require 'id3'
   
a = ID3::AudioFile.new("mp3/a.mp3")
t1 = a.write                            
a1 = a.writeAudio

aa = ID3::AudioFile.new( t1 )
t2 = aa.write
a2 = aa.writeAudio

aaa = ID3::AudioFile.new( t2 )
t3 = aaa.write
a3 = aaa.writeAudio
 
a.audioLength
aa.audioLength
aaa.audioLength

` ls -l t1 t2 t3`

# to create a test file

File.open("mp3/test.mp3", "w+") { |f|
 256.times { |i|
    f.putc i
 }
}

# -------------------------------------------------------------------------------- 

 
require 'id3'

a = ID3::AudioFile.new("mp3/a.mp3")
b = ID3::AudioFile.new("mp3/b.mp3")
c = ID3::AudioFile.new("mp3/c.mp3")
d = ID3::AudioFile.new("mp3/d.mp3")
e = ID3::AudioFile.new("mp3/reeeee.mp3")
a = ID3::AudioFile.new("mp3/King_Crimson_-_Three_of_a_Perfect_Pair_-_06_-_Industry.mp3")

d.tagID3v2["TMEDIATYPE"].flags
  
  d.tagID3v2.version
  d.tagID3v2["ARTIST"].rawflags
  d.tagID3v2["ARTIST"].flags
    
 d.tagID3v2["ARTIST"].raw
 d.tagID3v2["ARTIST"].rawheader
 d.tagID3v2["ARTIST"].rawdata
  
  
t = ID3::Tag2.new
t.read("mp3/b.mp3")

t["COMMENT"]
 t["COMMENT"].order

 t["COMMENT"]["bla"] =3
 


t['COMMENT'].rawdata.hexdump
 
 

t2["SONGLEN"].rawdata.hexdump
t2["SONGLEN"].dump.hexdump


# to check which symbols don't have a matching pack/unpack pattern:
  
(ID3::Framename2symbol["2.2.0"].values + 
   ID3::Framename2symbol["2.3.0"].values + 
   ID3::Framename2symbol["2.4.0"].values).uniq.each { |symbol|
       print "SYMBOL: #{symbol} not defined!\n"       if ! ID3::FrameName2FrameType[symbol]
}


 
  ID3::FrameName2FrameType["ARTIST"]
  ID3::FrameName2FrameType
  
 
 t2["ARTIST"].raw
 
 t2["ARTIST"].rawdata
 
 
 
 
 t1 = ID3::Tag2.new
 t1.read("mp3/b.mp3")
 t1["ARTIST"]
 

