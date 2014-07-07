#!/usr/bin/env ruby
require 'open-uri'
require "net/http"
require 'JSON'

# Increase coolness
system("color 0A")

# Generate a list of stackoverflow questions, ignoring any qustions that give a bad response when a request is made
begin 
  arg = 1
  api = "http://api.stackexchange.com"
  request = "/2.2/search?page=#{arg}&order=desc&sort=activity&intitle=sort&site=stackoverflow"
  uri = URI.parse(api)
  http = Net::HTTP.new(uri.host, uri.port)
  doc = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(doc)
  puts response.code
end while response.code.to_i > 400

# Get a JSON from every accepted link, then find the 'link' component of said JSON, and store the link if 'is_answered' is true
i = 0
links = Array.new()
json = http.get(request).body
json = JSON.parse(json)
json['items'].each do |data|
  if (data['is_answered'] == true) 
    links[i] = data['link']
    i += 1
  end
end

# Given every link from the past step, break it up into smaller components delimited by slashes, storing these components in the 'broken_link' array
#i = 0
broken_link = Array.new()
links.length.times do |i|
  broken_link[i] = links[i].to_s.split("/")
end

# Repair the broken links, chopping off the first couple of characters so that we only have a request, not a URL
repaired_request = Array.new()  
broken_link.length.times do |i|
  broken_link[i].length.times do |j|
    if (j > 2) 
      repaired_request[i] = repaired_request[i].to_s + "/" + broken_link[i][j].to_s 
    end
  end
end

# Get the HTML bodies for every generated URL/Request pair, store them in a_response
a_uri = Array.new()
a_http = Array.new()
a_doc = Array.new()
a_response = Array.new()
site = "http://stackoverflow.com"
links.length.times do |i|
  a_uri[i] = URI.parse(site)
  a_http[i] = Net::HTTP.new(a_uri[i].host, a_uri[i].port)
  a_response[i] = a_http[i].get(repaired_request[i]).body()
  puts a_http[i]
#  puts a_response[i]
end

all_code = Array.new()
a_response.length.times do |i|
  a_response[i].to_s.gsub!("</code>", "<code>")
  all_code[i] = a_response[i].to_s.split("<code>")
end

code = Array.new()
all_code.length.times do |i|
  all_code[i].length.times do |j|
    if(j % 2 == 1)
      code[code.length] = all_code[i][j]
    end
  end
end

puts code
