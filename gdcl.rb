#!/usr/bin/ruby -KuU
# encoding: utf-8

# invoke with:
# ruby gdcl.rb
# (for interactive search)
# OR
# ruby gdcl.rb [group] [keyword]
# (for non-interactive search)

########################

require 'yaml'
require 'fileutils'
require 'zlib'

config_dir = Dir.home + "/.config/gdcl/"
xdg = "/etc/xdg/gdcl/"
script_dir = File.expand_path(File.dirname(__FILE__)) + "/"

# read config file from default directory or cwd, otherwise quit
if File.exist?(config_dir + "config.yml")
  config = YAML::load(File.read(config_dir + "config.yml"))
elsif File.exist?(xdg + "config.yml")
  config = YAML::load(File.read(xdg + "config.yml"))
  FileUtils.mkdir_p config_dir
  FileUtils.cp xdg + "config.yml", config_dir
elsif File.exist?(script_dir + "config.yml")
  config = YAML::load(File.read(script_dir + "config.yml"))
  FileUtils.mkdir_p config_dir
  FileUtils.cp script_dir + "config.yml", config_dir
else
  abort("        No configuration file found. Please make sure config.yml is located
        either in the config folder under your home directory (i.e.,
        ~/.config/gdcl/config.yml), or in the same directory as the gdcl.rb
        executable.")
end

# set defaults from config
group = config[:group]
default_group = config[:default_group]
kword = config[:kword]
interactive_search = config[:interactive_search]
header_footer = config[:header_footer]
dict_dir = config[:dict_dir].gsub(/^~/, Dir.home)
search_term = config[:search_term]
del_dict = config[:del_dict]
markup = /#{config[:markup]}/
markup_replace = config[:markup_replace]


# list available groups
avail_group = Dir.glob(dict_dir + "*").select {|f| File.directory? f}
print_avail_group = ""

# make a nice bracketed list of available groups
avail_group.sort.each do |dir|
  strip_path = dir.gsub(/.*\//, "")
  print_avail_group << "[#{strip_path}], "
end

# either run search automatically with provided args, or use interactive mode
if ARGV[0] then group = ARGV[0] end
if ARGV[1] then kword = ARGV[1] end
if ARGV[0] && ARGV[1] then interactive_search = false end

# option to select a group interactively instead of specifying one in config section above
if group == ""
  puts "  Please select a dictionary group to search from the following available groups:"
  puts "  " + print_avail_group.gsub(/, $/,"")
  group = gets.chomp
end

if group == ""
  if default_group != ""
    group = default_group
  else
    abort("No group specified")
  end
end

# quit if user supplied a group that doesn't exist
if !avail_group.include?(dict_dir + group) then abort("Specified group does not exist") end

# working directory location
dir = Dir[dict_dir + "#{group}/**/*.dsl.dz"]

# don't search any of the dictionaries specified for removal in config
del_dict.each {|x| dir.delete(dict_dir + group + "/" + x)}

# get search term
if kword == ""
  puts "Enter a search term (currently searching in group [#{group}]):"
  kword = gets.chomp
end

# keep running the search loop until this is true
quitapp = false

# main dictionary search loop
while quitapp != true
  hit = 0
  results = ""
  total = 0

  search_term = /^#{kword}/

  dir.sort.each do |dict|
    dict_name = Zlib::GzipReader.open(dict, :external_encoding => "UTF-16LE").read.each_line.first.strip.sub("\xEF\xBB\xBF", "").gsub(/#NAME\s+"(.*)"/,"\\1")
    dict_header = "== " + dict_name + " ==\n"
    if header_footer == false then dict_header = "" end
    results << dict_header
    print dict_header
    counter = 0
    Zlib::GzipReader.open(dict, :external_encoding => "UTF-16LE") do |file|
      headword = ""
      file.read.each_line do |line|
        if line.match(/^\t/)
	  line_strip = line.gsub(markup,markup_replace)
          if hit > 0
            results << line_strip.gsub("~", headword)
	    puts line_strip.gsub("~", headword)
	    hit +=1
          end
        elsif line.match(search_term)
          results << line
	  puts line
          headword = line.chomp
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

  if interactive_search == true && total != 0
    puts "Display results in pager? (y/n)"

    gets.chomp == "y" ? IO.popen("less", "w") { |f| f.puts results } : (puts "Search complete.")

#     IO.popen("less", "w") { |f| f.puts results }
  end
  if interactive_search == true

    puts "\nSearch again in [#{group}] or enter 'q' to quit, or 'g' to change group:"

    kword = gets.chomp

# quit if user enters "q"
    kword == "q" || kword == "" ? quitapp = true : quitapp = false

# switch group if user enters "g"
    if kword == "g"
      puts "Please select a new group to search in (current group is [#{group}])"
      puts "  " + print_avail_group.gsub(/, $/,"")
      group = gets.chomp
      dir = Dir[dict_dir + group + "/**/*.dsl.dz"]	# change working directory location
      del_dict.each {|x| dir.delete(dict_dir + group + "/" + x)}	    # remove specified dictionaries

      puts "Now searching in group [#{group}]"
      puts "Please enter search term:"
      kword = gets.chomp
    end
  else
    quitapp = true
  end

end
