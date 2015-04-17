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
require 'optparse'
require 'nokogiri'
require 'open-uri'

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

# command-line options
options = {}
OptionParser.new do |opts|
  opts.banner = "  gdcl - Command-Line Dictionary Lookup Tool\n\n  Usage: gdcl.rb [options] [dictionary group] [search term]"

  opts.on("-c", "--names [GROUP]", "List all dictionaries in specified group by canonical name") { |v| v ? options[:dict_name] = v : options[:dict_name] = true }
  opts.on("-C", "--case-off", "Enable case insensitive search") { options[:case_off] = true }
  opts.on("-d", "--dict-directory DIRECTORY", "Directory in which to look for dictionaries") { |v| options[:dict_dir] = v }
  opts.on("-f", "--forvo LANGUAGE", "Play back audio pronunciations from forvo.com") { |v| options[:forvo] = v }
  opts.on("-g", "--groups", "Print a list of all available dictionary groups") { options[:groups] = true }
  opts.on("-h", "--help", "Print this help message") { puts opts; exit }
  opts.on("-H", "--history", "Record search term history in a log file") { options[:history] = true }
  opts.on("-i", "--ignore FILENAMES", "List of dictionaries to ignore while searching") { |v| options[:ignore] = v }
  opts.on("-l", "--list GROUP", "List all dictionaries in specified group") { |v| options[:list] = v }
  opts.on("-L", "--logfile DIRECTORY", "Directory in which to store search log") { |v| options[:logfile] = v }
  opts.on("-m", "--markup", "Don't strip DSL markup from output") { options[:markup] = true }
  opts.on("-n", "--no-headers", "Remove headers and footers from results output") { options[:noheaders] = true }
  opts.on("-p", "--pager-off", "Don't prompt to open results in pager") { options[:pager_off] = true }
  opts.on("-r", "--restrict FILENAME", "Restrict search to the specified dictionary only") { |v| options[:restrict] = v }

end.parse!

# apply command-line options if any or else use defaults from config
group = config[:group]
default_group = config[:default_group]
kword = config[:kword]
interactive_search = config[:interactive_search]
if options[:noheaders] == true
  header_footer = false
else
  header_footer = config[:header_footer]
end
if options[:pager_off] == true
  pager_off = true
else
  pager_off = config[:pager_off]
end
if options[:dict_dir]
  dict_dir = options[:dict_dir].gsub(/^~/, Dir.home)
else
  dict_dir = config[:dict_dir].gsub(/^~/, Dir.home)
end
search_term = config[:search_term]
if options[:ignore]
  del_dict = options[:ignore].split(",")
else
  del_dict = config[:del_dict].split(",")
end
if options[:markup] == true
  markup = ""
else
  markup = /#{config[:markup]}/
end
markup_replace = config[:markup_replace]
if options[:history] || config[:history]
  if options[:logfile]
    log_location = File.join(options[:logfile], "history.txt")
  elsif config[:logfile]
    log_location = File.join(config[:logfile].gsub(/^~/, Dir.home), "history.txt")
  else
    log_location = File.join(config_dir, "history.txt")
  end
end

# list available dictionaries in group
if options[:list]
  dir = Dir[dict_dir + "#{options[:list]}/**/*.dsl.dz"]
  dir.sort.each do |dict|
    dict_file = dict.gsub(/.*\/(.*)\.dsl\.dz$/, "\\1")
    if options[:dict_name]
      dict_name = Zlib::GzipReader.open(dict, :external_encoding => "UTF-16LE").read.each_line.first.strip.sub("\xEF\xBB\xBF", "").gsub(/#NAME\s+"(.*)"/,"\\1")
      puts dict_file + "\t" + dict_name
    else
      puts dict_file
    end
  end
  exit
end

# list dictionaries by name
if options[:dict_name]
  dir = Dir[dict_dir + "#{options[:dict_name]}/**/*.dsl.dz"]
  dict_name = []
  dir.sort.each do |dict|
    dict_name.push(Zlib::GzipReader.open(dict, :external_encoding => "UTF-16LE").read.each_line.first.strip.sub("\xEF\xBB\xBF", "").gsub(/#NAME\s+"(.*)"/,"\\1"))
  end
  puts dict_name
  exit
end

# list available groups
avail_group = Dir.glob(dict_dir + "*").select {|f| File.directory? f}
print_avail_group = ""

if options[:groups] == true
  puts "**Available dictionary groups**"
  avail_group.sort.each { |g| puts g.gsub(/.*\//, "")}
  exit
end

# make a nice bracketed list of available groups
avail_group.sort.each do |dir|
  strip_path = dir.gsub(/.*\//, "")
  print_avail_group << "[#{strip_path}], "
end

# get forvo pronunciations
if options[:forvo]
  key = config[:forvo_key]
  if key == nil then abort("        Forvo key not set in user config.") end
  lang = options[:forvo]
  ARGV[0] ? lookup = ARGV[0] : abort("missing search term")
  doc = Nokogiri::XML(open(URI.encode("http://apifree.forvo.com/key/#{key}/format/xml/action/word-pronunciations/word/#{lookup}/language/#{lang}")))
  hits = doc.xpath("//items").first.attribute("total").content.to_i
  path = doc.xpath("//pathogg")
  path.each do |link|
    puts "Playing result #{path.index(link) + 1} of #{hits.to_s} in #{lang} from forvo.com..."
    `mplayer -really-quiet #{link.content}`
  end
  exit
end

# either run search automatically with provided args, or use interactive mode
if ARGV[0] then group = ARGV[0] end
if ARGV[1] then kword = ARGV[1] end
if ARGV[0] && ARGV[1] then interactive_search = false end

# option to select a group interactively instead of specifying one in config section above
if group == ""
  puts "  Please select a dictionary group to search from the following available groups:"
  puts "  " + print_avail_group.gsub(/, $/,"")
  group = $stdin.gets.chomp
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
if options[:restrict]
  rlist = options[:restrict].split(",")
  dir = []
  full_list = Dir[dict_dir + "#{group}/**/*.dsl.dz"]
  full_list.each do |f|
    rlist.each { |r| if f.gsub(/.*\/(.*)\.dsl\.dz$/, "\\1").match(r) then dir.push(f) end }
  end
#   full_list.each { |f| if f.gsub(/.*\/(.*)\.dsl\.dz$/, "\\1").match(rlist[0]) then dir.push(f) end }
#   rlist.each { |f| dir.push( dict_dir + group + "/" + f + ".dsl.dz") }
else
  dir = Dir[dict_dir + "#{group}/**/*.dsl.dz"]
end

# don't search any of the dictionaries specified for removal in config
del_dict.each {|x| dir.delete(dict_dir + group + "/" + x + ".dsl.dz")}

# get search term
if kword == ""
  puts "Enter a search term (currently searching in group [#{group}]):"
  kword = $stdin.gets.chomp
end

# prevent error if user enters empty search query
if kword == "" then abort("Invalid search term") end

# log terms
def log_term(kw, gr, loc)
  logline = "#{Time.now}\t" + kw + "\t(" + gr + ")\n"
  logfile = File.open(loc, "a") { |l| l << logline }
end

# keep running the search loop until this is true
quitapp = false

# main dictionary search loop
while quitapp != true
  hit = 0
  results = ""
  total = 0

# if logging is enabled then log search info to file
if log_location then log_term(kword, group, log_location) end

# case-sensitive search off by default
  if options[:case_off]
    search_term = /^#{kword}/i
  else
    search_term = /^#{kword}/
  end

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
          line = line.gsub(/\\\[(.*?)\\\]/,"%%%\\1%%%")
          line_strip = line.gsub(markup,markup_replace)
          line_strip = line_strip.gsub(/%%%(.*?)%%%/,"\[\\1\]")
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
#           print "\rSearching for #{kword}... A total of #{total} results found so far in [#{group}]"
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

  if interactive_search == true && total != 0 && pager_off != true
    puts "Display results in pager? (y/n)"

    $stdin.gets.chomp == "y" ? IO.popen("less", "w") { |f| f.puts results } : (puts "Search complete.")

#     IO.popen("less", "w") { |f| f.puts results }
  end
  if interactive_search == true

    puts "\nSearch again in [#{group}] or enter 'q' to quit, or 'g' to change group:"

    kword = $stdin.gets.chomp

# quit if user enters "q"
    kword == "q" || kword == "" ? quitapp = true : quitapp = false

# switch group if user enters "g"
    if kword == "g"
      puts "Please select a new group to search in (current group is [#{group}])"
      puts "  " + print_avail_group.gsub(/, $/,"")
      group = $stdin.gets.chomp
      dir = Dir[dict_dir + group + "/**/*.dsl.dz"]	# change working directory location
      del_dict.each {|x| dir.delete(dict_dir + group + "/" + x + ".dsl.dz")}	    # remove specified dictionaries

      puts "Now searching in group [#{group}]"
      puts "Please enter search term:"
      kword = $stdin.gets.chomp
    end
  else
    quitapp = true
  end
end
