#!/usr/bin/env ruby

#
# A simple script to build scripts with the tool
#

require File.dirname(__FILE__)+'/../init.rb'

@c = FrontCompiler.new

Dir.entries(File.dirname(__FILE__)+'/in').each do |file|
  unless %w{. ..}.include?(file)
    puts "Compacting #{file}"
    File.open(File.dirname(__FILE__)+"/out/#{file}", "w") do |f|
      src = @c.compact_file(File.dirname(__FILE__)+"/in/#{file}")
      f.write file.slice(file.size-3, file.size) == '.js' ? src.create_self_build : src
    end
  end
end