#!/usr/bin/ruby -KuU
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'yaml'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-m", "--mp3", "Use mp3 files instead of ogg (default)") { options[:mp3] = true }
  opts.on("-l", "--list", "List all pronunciations") { options[:list] = true }
  opts.on("-u", "--urls", "Print a list of audio urls") { options[:urls] = true }
  opts.on("-a", "--play-all", "Play back all pronunciations without interaction") { options[:play_all] = true }
  opts.on("-s", "--save", "Save all audio files to disk") { options[:save] = true }

end.parse!

config_dir = Dir.home + "/.config/gdcl/"

# read key from config file, otherwise quit
if File.exist?(config_dir + "config.yml")
  config = YAML::load(File.read(config_dir + "config.yml"))
else
  abort("        No configuration file found in user home.")
end

key = config[:forvo_key]
if key == nil then abort("        Forvo key not set in user config.") end

format = "ogg"
if options[:mp3] == true then format = "mp3" end

# get language
if ARGV[0]
  @lang = ARGV[0]
else
  puts "Enter language code:"
  # full list of supported codes here: http://www.forvo.com/languages-codes/
  @lang = $stdin.gets.chomp
end

# get lookup word or phrase
if ARGV[1]
  @lookup = ARGV[1]
else
  puts "Enter word to pronounce:"
  @lookup = $stdin.gets.chomp
end

# quit if no language or lookup supplied
if @lang == "" || @lookup == ""
  abort("Insufficient information provided")
end

# read in xml from Forvo API
@doc = Nokogiri::XML(open(URI.encode("http://apifree.forvo.com/key/#{key}/format/xml/action/word-pronunciations/word/#{@lookup}/language/#{@lang}")))

# get the number of results
# hits = @doc.xpath("//pathogg").length
hits = @doc.xpath("//items").first.attribute("total").content.to_i
hits == 1 ? plural = "" : plural = "s"
hits == 0 ? colondot = "." : colondot = ":"

# print out the total number of results found
unless options[:urls] == true && options[:list] != true
  puts hits.to_s + " pronunciation#{plural} found for \"#{@lookup}\" in #{@lang}#{colondot}"
  puts
end

# parse API for various parameters
id = @doc.xpath("//id")
username = @doc.xpath("//username")
times_listened = @doc.xpath("//hits")
sex = @doc.xpath("//sex")
country = @doc.xpath("//country")
rating = @doc.xpath("//rate")
votes = @doc.xpath("//num_votes")
pos_votes = @doc.xpath("//num_positive_votes")


def play_all(format)
  path = @doc.xpath("//path#{format}")
  path.each do |link|
    puts "Now playing pronunciation ##{path.index(link) + 1}..."
    `mplayer -really-quiet #{link.content}`
  end
end

def play_one(format,num)
  link = @doc.xpath("//path#{format}")[num - 1]
  puts "Now playing pronunciation ##{num}..."
  `mplayer -really-quiet #{link.content}`
end

def save_audio(format,index)
  location = @doc.xpath("//path#{format}")[index].content
  filename = "#{@lang}_#{@lookup.gsub(/\s+/, "-")}_#{index + 1}.#{format}"
  `curl -s #{location} > "#{filename}"`
  puts "Audio saved to #{filename}."
end

def list_urls(format,num)
  path = @doc.xpath("//path#{format}")
  path.each do |link|
    s = path.index(link)
    if num == "yes"
      s_format = "  #{s + 1}. "
    elsif num == "no"
      s_format = ""
    end
    location = link.content
    puts "#{s_format}#{location}"
  end
end

def pronunciation_list(id,votes,rating,pos_votes,username,sex,country)
  id.each do |item|
    s = id.index(item)
    print_rating = ""
    if votes[s].content != 0
      neg_votes = rating[s].content.to_i - pos_votes[s].content.to_i
      print_rating = "\t\t#{rating[s].content} [+#{pos_votes[s].content} #{neg_votes}]"
    end
    puts "  #{s + 1}. by #{username[s].content} (#{sex[s].content} from #{country[s].content})#{print_rating}"
  end
  puts
end

if options[:play_all] == true
  play_all(format)
  exit
end

if options[:list] == true
  pronunciation_list(id,votes,rating,pos_votes,username,sex,country)
  if options[:urls] != true
    exit
  end
end

if options[:urls] == true
  num = ""
  if options[:urls] != true
    num = "yes"
  elsif options[:list] == true
    num = "yes"
  else
    num = "no"
  end
  list_urls(format,num)
  exit
end

if options[:save] == true
  if hits == 0
    puts "No matching pronunciations found for \"#{@lookup}\" in #{@lang}"
  else
    num = 0
    id.each do |item_id|
      save_audio(format,num)
      num += 1
    end
  end
  exit
end

unless hits == 0
  pronunciation_list(id,votes,rating,pos_votes,username,sex,country)
  puts
  puts "Select a number to hear the corresponding pronunciation, or press \"a\" to hear all available pronunciations."
  selection = $stdin.gets.chomp

  if selection == "a"
    play_all("ogg")
  elsif /^\d+$/.match(selection)
    play_one("ogg",selection.to_i)
  else
    abort("Nothing selected.")
  end

  puts "Enter a number to save pronunciation to disk, or any other key to quit"
  save = $stdin.gets.chomp

  if /[^\d+$]/.match(save) || save == "" || hits == 0
    exit
  else
    save_idx = save.to_i - 1
    save_audio(format,save_idx)
  end
end
