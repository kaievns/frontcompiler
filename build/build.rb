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
      f.write @c.compact_file(File.dirname(__FILE__)+"/in/#{file}")
    end
  end
end