#!/usr/bin/env ruby
require 'open-uri'
require "net/http"
require 'JSON'

# Increase coolness
system("color 0A")

# Generate a list of stackoverflow questions, ignoring any qustions that give a bad response when a request is made
begin 
  arg = 3
  api = "http://api.stackexchange.com"
  request = "/2.2/search?page=#{arg}&order=desc&sort=activity&intitle=c&site=stackoverflow"
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

# Using Regex, remove all searches that appear to be in a non-C language
c_code = Array.new()
code.length.times do |i|         
  code[i].to_s.gsub!("&gt;", ">")       # Get rid of some odd triangle bracket errors     
  code[i].to_s.gsub!("&lt;", "<")                                                                    # Eliminate Java                        # Eliminate C++             # Eliminate Perl/Ruby/Python
  if (/(int|bool|void|float|double|long|char)\s\w+([\w+,]+)/.match(code[i]) and !(/(public|private|extends|implements|static)/.match(code[i])) and !(/(namespace|::|self)/.match(code[i])) and !(/def/.match(code[i])))
    c_code[c_code.length] = code[i]
  end
end

all_c_code_lines = Array.new()
c_code.length.times do |i|
  all_c_code_lines[all_c_code_lines.length] = c_code[i].to_s.split("\n")
end

c_code_lines = Array.new()
all_c_code_lines.length.times do |i|
  all_c_code_lines[i].length.times do |j|
    c_code_lines[c_code_lines.length] = all_c_code_lines[i][j]
  end
end

# Determine any prototypes/includes
includes = Array.new()
prototypes = Array.new()
prototype_lines = Array.new()
c_code_lines.length.times do |i|
  if (/#include <\w+.h>/.match(c_code_lines[i]))
    includes[includes.length] = c_code_lines[i]
  end
  if (/(int|void|bool|double|float)\s\w+\(/.match(c_code_lines[i]) and !/\=/.match(c_code_lines[i]))         # \(.+\)
    p1 = c_code_lines[i].split("{")
    prototypes[prototypes.length] = p1[0]
    prototype_lines[prototype_lines.length] = i
  end
end

# Clean up any includes
includes.length.times do |i|
  includes.length.downto(i + 1) do |j|
    if (includes[j].to_s.eql? includes[i].to_s)
      includes[j] = includes[j + 1]
    end
  end
end
includes = includes.reject! { |i| i.to_s.empty? }

# Clean up prototypes
prototypes.length.times do |i|
  temp_prototype = prototypes[i].split(";")
  prototypes[i] = temp_prototype[0].to_s.strip() + ";"
end
prototypes.reject! { |i| i.to_s.empty? }                      # Get rid of all the empty elements
prototype_lines.reject! { |i| i.to_s.empty? }
prototype_lines.length.downto(1) do |i|
  prototype_lines[i] = prototype_lines[i - 1]
end

startln = 0
begin
  startln += 1
end while !(/(int|void|bool|double|float)\s\w+\(/.match(c_code_lines[startln]) and !/\=/.match(c_code_lines[startln]))
prototype_lines[0] = startln
puts prototype_lines[0]

functions = Array.new()
(prototype_lines.length - 1).times do |i|
  opened = 0
  fn_len = 0
  for j in ((prototype_lines[i].to_i)..prototype_lines[i + 1])
    if /{/.match(c_code_lines[j])
      opened += 1
    elsif /}/.match(c_code_lines[j])
      opened -= 1
    end
    if (opened == 0)
      fn_len = j
      break
    end
  end
  if (fn_len == 0)
    fn_len = prototype_lines[i + 1]
  end
  for j in (prototype_lines[i]..fn_len)
    functions[i] = functions[i].to_s + c_code_lines[j].to_s + "\n"
  end
end

# Clean up functions
iteration = 0
functions.length.times do |i|
  if (i % 2 == 0)
    functions[iteration] = functions[i]
    iteration += 1
  end  
end

puts functions
