#!/usr/bin/ruby -KuU
# encoding: utf-8

# invoke with:
# ruby gdcl.rb
# (for interactive search)
# OR
# ruby gdcl.rb [group] [keyword]
# (for non-interactive search)

########################

# ==Configuration options==

# Group name (at the moment this should be the name of a subfolder in your Goldendict dictionary directory)
group = ""

# Keyword to search for
kword = ""

# Set to false for non-interactive search (e.g. to pipe the search results)
# Defaults to non-interactive search if group and keyword are specified as command-line parameters
interactive_search = true

# Set to false to turn off header and footer information (i.e. dictionary name, number of hits for search term)
header_footer = true

# Temporary working directory where gdcl will store files
# Note: if you used gdcg.rb to set up your dsl files, you should probably use the default here
temp_dir = "#{Dir.home}/.goldendict/gdcl/tmp"

# Search pattern (specify a pattern to search for, default is headwords starting with keyword; include regex between // slashes)
# search_term = /^#{kword}/
# search_term = /^#{kword}$/	# searches for strictly matching headwords

# optionally exlude the following dictionaries
del_dict = [""]
# del_dict = ["somedict.dsl","someotherdict.dsl",""]

# dsl markup options
# remove markup (i.e. all text between "[]" tags); default is to remove markup
markup = /\[.*?\]/	# remove dsl markup
# markup = ""	# uncomment to allow dsl markup in entries
markup_replace = ""


#######################

# list available groups
avail_group = Dir.glob("#{temp_dir}/*").select {|f| File.directory? f}
print_avail_group = ""

avail_group.sort.each do |dir|
  strip_path = dir.gsub(/.*\//, "")
  print_avail_group << "[#{strip_path}], "
end

if ARGV[0] then group = ARGV[0] end
if ARGV[1] then kword = ARGV[1] end
if ARGV[0] && ARGV[1] then interactive_search = false end

# option to select a group interactively instead of specifying one in config section above
if group == ""
  puts "  Please select a dictionary group to search from the following available groups:"
  puts "  " + print_avail_group.gsub(/, $/,"")
  group = gets.chomp
end

# working directory location
dir = Dir[temp_dir + "/" + group + "/*.dsl"]

# don't search any of the dictionaries specified for removal in config
del_dict.each {|x| dir.delete(temp_dir + "/" + group + "/" + x)}

# get search term
if kword == ""
  puts "Enter a search term (currently searching in group [#{group}]):"
  kword = gets.chomp
end

quitapp = false

while quitapp != true
  hit = 0
  results = ""
  total = 0

  search_term = /^#{kword}/

  dir.sort.each do |dict|
#     dict_name = dict.gsub("tmp/#{group}/","").gsub(".dsl","").gsub("_"," ").gsub(/^(.)/){$1.upcase}
    dict_name = File.open(dict,"rb:UTF-16LE").readlines[0].strip.sub("\xEF\xBB\xBF", "").gsub(/#NAME\s+"(.*)"/,"\\1")
    dict_header = "== " + dict_name + " ==\n"
    if header_footer == false then dict_header = "" end
    results << dict_header
    print dict_header
    counter = 0
    File.open(dict,"rb:UTF-16LE") do |file|
      file.each do |line|
        if line.match(/^\t/)
	  line_strip = line.gsub(markup,markup_replace)
          if hit > 0
            results << line_strip
	    puts line_strip
	    hit +=1
          end
        elsif line.match(search_term)
          results << line
	  puts line
          hit = 1
	  counter +=1
	  total +=1
# 	  print "\rSearching for #{kword}... A total of #{total} results found so far in [#{group}]"
        elsif line.encode(universal_newline: true).match(/^$/)
	  hit = 0
        end
      end
    end
    if counter == 1
      dict_footer = "\n#{counter} result found in [#{dict_name}]\n\n\n"
      if header_footer == false then dict_footer = "" end
      results << dict_footer
      print dict_footer
    else
      dict_footer = "\n#{counter} results found in [#{dict_name}]\n\n\n"
      if header_footer == false then dict_footer = "" end
      results << dict_footer
      print dict_footer
    end
  end

  results_footer = "A total of #{total} result(s) found in [#{group}] for the term \"#{kword}\".\n"
  if header_footer == false then results_footer = "" end
  print results_footer

  if interactive_search == true
    puts "Display results in pager? (y/n)"
  
    gets.chomp == "y" ? IO.popen("less", "w") { |f| f.puts results } : (puts "Search complete.")
  
#     IO.popen("less", "w") { |f| f.puts results }

    puts "\nSearch again in [#{group}] or enter 'q' to quit, or 'g' to change group:"

    kword = gets.chomp
    kword == "q" ? quitapp = true : quitapp = false

    if kword == "g"
      puts "Please select a new group to search in (current group is [#{group}])"
      group = gets.chomp
      dir = Dir[temp_dir + "/" + group + "/*.dsl"]	# change working directory location
      del_dict.each {|x| dir.delete(temp_dir + "/" + group + "/" + x)}	    # remove specified dictionaries

      puts "Now searching in group [#{group}]"
      puts "Please enter search term:"
      kword = gets.chomp
    end
  else
    quitapp = true
  end

end

# File.open("yue_teshu.dsl","rb:UTF-16LE") do |file|
#   file.each do |line|
# #     puts line
#     if line.match("\t")
#       if hit == "yes"
#         puts line
#         hit = ""
#       end
#     elsif line.match("0既")
#       puts line
#       hit = "yes"
#     end
#   end
# end
