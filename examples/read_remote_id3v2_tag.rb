# -*- coding: undecided -*-

# See also: http://stackoverflow.com/questions/7656950/read-id3-tags-of-remote-mp3-file-in-ruby-rails

require 'rubygems'
require 'awesome_print'    # debugging only

require 'net/http'
require 'uri'
require 'id3'
require 'hexdump'          # debugging only

# --------------------------------------------------------------------------------------------

def get_remote_id3v2_tag( file_url )
  id3v2_tag_size = get_remote_id3v2_tag_size( file_url )
  if id3v2_tag_size > 0
    buffer = get_remote_bytes(file_url, id3v2_tag_size )
    tag2 = ID3::Tag2.new
    tag2.read_from_buffer( buffer )
    return tag2
  else
    return nil
  end
end

def get_remote_id3v2_tag_size( file_url )
  buffer = get_remote_bytes( file_url, 100 )
  if buffer.bytesize > 0
    return buffer.ID3v2_tag_size
  else
    return 0
  end
end

def get_remote_bytes( file_url, n)
  uri = URI(file_url)
  size = n   # ID3v2 tags can be considerably larger, because of embedded album pictures
  Net::HTTP.version_1_2  # make sure we use higher HTTP protocol version than 1.0
  http = Net::HTTP.new(uri.host, uri.port)
  resp = http.get( file_url , {'Range' => "bytes=0-#{size-1}"} )
  resp_code = resp.code.to_i
  if (resp_code >= 200 && resp_code < 300) then
    return resp.body
  else
    return ''
  end
end

# --------------------------------------------------------------------------------------------

file_url = 'http://www.unixgods.org/~tilo/ID3/example_mp3_file_with_id3v2.mp3'  # please specify a URL here for testing


puts "\nRemote File: \"#{file_url}\""

puts "\ncontains ID3v2 tag of size: #{get_remote_id3v2_tag_size( file_url )} Bytes"

tag2 =  get_remote_id3v2_tag( file_url )

puts "\nID3v3 Version: #{tag2.version}\n"

puts "\ncontains Frames:\n"
ap tag2.keys

puts "\nID3v2 Tag:\n"

ap( tag2 )

puts "\nID3v2 Hexdump:\n"

puts tag2.raw.hexdump(true)


