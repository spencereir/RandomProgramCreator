#!/usr/bin/env ruby
require 'open-uri'
require "net/http"
require 'JSON'
require './functions'

# Increase coolness
system("color 0A")

# Generate a list of stackoverflow questions, ignoring any qustions that give a bad response when a request is made
begin 
  arg = rand(30) + 1
  api = "http://api.stackexchange.com"
  request = "/2.2/search?page=#{arg}&order=desc&sort=activity&intitle=c&site=stackoverflow"
  uri = URI.parse(api)
  http = Net::HTTP.new(uri.host, uri.port)
  doc = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(doc)
  puts "Server at #{api + request} returned with response of " + response.code + ". " + (response.code.to_i > 400 ? "Failiure! Trying new page." : "Success!") 
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
  code[i].to_s.gsub!("&amp;", "&")
  code[i].to_s.gsub!("&gt;", ">")       # Get rid of some odd triangle bracket errors     
  code[i].to_s.gsub!("&lt;", "<")            
  code[i].to_s.gsub!("int argc, char *argv[]", "")                                                       # Eliminate Java                                            # Eliminate C++             # Eliminate Perl/Ruby/Python             # I don't like structs or doublepointers, and nothing good can come from underscores
  if (/(int|bool|void|float|double|long|char)\s[a-zA-Z]+([\w+,]+)/.match(code[i]) and !(/(public|private|extends|implements|static|extern)/.match(code[i])) and !(/(namespace|::|self)/.match(code[i])) and !(/def/.match(code[i])) and !(/(struct|\*\*|\_)/.match(code[i])))
    c_code[c_code.length] = code[i]
  end
end

# Parse all C code lines into a 2D array of C code lines
all_c_code_lines = Array.new()
c_code.length.times do |i|
  all_c_code_lines[all_c_code_lines.length] = c_code[i].to_s.split("\n")
end

# Parse the 2D array of C code lines into a 1D array of c code lines
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
includes[0] = "#include <stdio.h>"
includes[1] = "#include <stdlib.h>"
includes[2] = "#include <time.h>"
c_code_lines.length.times do |i|
  if(c_code_lines[i].to_s.strip.eql? "{") 
    c_code_lines[i] = ""
    c_code_lines[i - 1] += " {"
  end
  if (/#include <\w+.h>/.match(c_code_lines[i]))
    includes[includes.length] = c_code_lines[i]
  end
  if (/(int|void|bool|double|float)\s\w+\(/.match(c_code_lines[i]) and !/\=/.match(c_code_lines[i]))        
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

#Find out which line the first function starts on
startln = 0
begin
  startln += 1
end while !(/(int|void|bool|double|float)\s\w+\(/.match(c_code_lines[startln]) and !/\=/.match(c_code_lines[startln]))
prototype_lines[0] = startln

# Split all of the code into individual functioins, stored in the functions array
all_functions = Array.new()
(prototype_lines.length - 1).times do |i|
  opened = 0
  fn_len = 0
  for j in ((prototype_lines[i].to_i)..prototype_lines[i + 1])
    if /{/.match(c_code_lines[j])
      opened += 1
    end
    if /}/.match(c_code_lines[j])
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
    all_functions[i] = all_functions[i].to_s + c_code_lines[j].to_s + "\n"
  end
end

#Clean up functions
all_functions.reject! { |f| /\.\.\./.match(f) }
all_functions.reject! { |f| f.to_s.split("\n").length < 2 }
all_function_lines = Array.new()
all_functions.length.times do |i|
  all_function_lines[i] = all_functions[i].to_s.split("\n")
end

# Have fun figuring this one out :D
functions = Array.new()
all_functions.length.times do |i|
  f_name = ""
  f_return_val = ""
  f_args = Array.new()
  f_vars = Array.new()
  f_var_types = Array.new()                        
  f_line = all_function_lines[i][0]
  f_line.gsub!(/\(\s+/, "(")
  f_line_split = f_line.split(/(\(|\))/)
  f_paren_exp = f_line_split[2]
  f_line_split = f_line.split(" ") 
  f_return_val = f_line_split[0]
  f_name_split = f_line_split[1]
  f_name_split = f_name_split.split("(")
  f_name = f_name_split[0]
  f_args = f_paren_exp.split(",")
  f_num_params = f_args.length
  f_args.length.times do |i|
    f_args_split = f_args[i].split(" ")
    f_var_types[i] = f_args_split[0]
    f_vars[i] = f_args_split[1]
  end
  functions << Function.new(all_functions[i], f_name, f_return_val, f_num_params, f_vars, f_var_types)
end
functions.reject! { |f| /(int|void|bool|double|float)/.match(f.vars.join) }
# Now for the interesting part: Programs writing programs
program = "#ifndef true\n  #define true 1\n#endif\n\n#ifndef false\n  #define false 0\n#endif\n\n"

includes.each do |i|
  program += i + "\n"
end
program += "\n"

functions.length.times do |i|
  functions.length.times do |j|
    functions[i].replaceName(functions[j])         # Make sure that all function calls use the corrected name
  end
  program += functions[i].prototype + "\n"
end

program += "\nint main() {\n"
program += "\tsrand(time(0));\n"
program += "\tint num[10];\n"
program += "\tdouble dub[10];\n"
program += "\tfloat flo[10];\n"
program += "\tchar cha[10];\n"
program += "\tint i = 0;\n"
program += "\tfor(i = 0; i < 10; i++) {\n\t\tnum[i] = rand() % 100 + 1;\n\t\tdub[i] = rand() % 100 + 1;\n\t\tflo[i] = rand() % 100 + 1;\n\t\tcha[i] = rand() % 26 + 65;\n\t}\n" # Get some random variables

puts "Enter the desired number of iterations"
rep = gets.chomp.to_i
for i in (0..rep)
  params = []
  num = rand(functions.length)
  functions[num].numParams.times do |j|
    case functions[num].sVarTypes(j)
    when "int"
      params[j] = "num[" + rand(10).to_s + "]"
    when "bool"
      params[j] = (rand(2) ? "true" : "false")
    when "dub"
      params[j] = "dub[" + rand(10).to_s + "]"
    when "float"
      params[j] = "flo[" + rand(10).to_s + "]"
    when "char"
      params[j] = "cha[" + rand(10).to_s + "]"
    end
  end
  program += "\t" + functions[num].call(params, 1) 
end

program += "\n\tgetchar();\n\treturn 0;\n}"
functions.length.times do |i|
  program += functions[i].function + "\n\n"
end
program_name = "00" + (0...8).map { (65 + rand(26)).chr }.join     # Generate a random name for the program
program_path = program_name + ".c"
program.gsub!("bool", "int")            # GCC pls
program.gsub!("getch();", "getchar();")
program.gsub!("clrscr();", "system(\"cls\");")

File.open(program_path, 'w') do |f|
  f.puts program
end

system("gcc -c #{program_path} -o #{program_name}.exe -std=c99")
system("#{program_name}.exe")

puts "\n\nProgram created! There's like a 99.9% chance something went wrong with it, so go ahead and debug at your leisure! Program is stored at #{program_path}"
puts "\n\nRandom Program Creator made by Spencer Whitehead"
gets
