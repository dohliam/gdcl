#!/usr/bin/ruby -KuU
# encoding: utf-8

require 'fileutils'

# Run this script to set up your dictionaries in groups for quicker searching.
# By default it looks for groups of dictionaries arranged in subfolders under your Goldendict folder.
# NOTE: Using this script is optional: it merely simplifies the process of creating dictionary groups.
# You can configure gdcl to use any arbitrary group of dictionaries by changing the default directory in the configuration options.
# To search, use gdcl.rb rather than this script.

# config
dict_home = "#{Dir.home}/.goldendict/dic/*"
script_home = "#{Dir.home}/.goldendict/gdcl/"

avail_groups = ""
avail_groups_fullpath = Dir[dict_home]
avail_groups_fullpath.sort.each { |g| avail_groups << "[#{g.gsub(dict_home.gsub(/\*/,""),"")}] " }

puts "Enter the name of a dictionary group to configure"
puts "Available groups:"
puts avail_groups
group = gets.chomp
tmp_dir = script_home + "tmp/" + group

FileUtils.mkdir_p tmp_dir

src_dict = Dir[dict_home + group + "/**/*.dsl.dz"]

src_dict.each do |file|
  unzipped = file.gsub(/\.dz/, "").gsub(/.*\//, "")
  unless File.file?(tmp_dir + "/" + unzipped)
    FileUtils.cp file, tmp_dir
  end
end

dz = Dir[tmp_dir + "/*.dsl.dz"]

dz.each do |zip|
  `dictunzip "#{zip}"`
end

avail_dict = Dir[tmp_dir + "/*.dsl"]

puts "  The following dictionaries are available in group [#{group}]:"

avail_dict.each do |dsl|
  puts dsl.gsub(tmp_dir + "/","").gsub(".dsl","").gsub("_"," ").gsub(/^(.)/){$1.upcase}.gsub(/(\s+.)/){$1.upcase}
end
