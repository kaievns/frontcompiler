#
# This module contains the hashes compactor functionality
# 
# This module is a part of the JavaScript class and taken out
# just to keep the things simple
# 
# Copyright (C) 2009 Nikolay V. Nemshilov aka St.
#
class FrontCompiler
  class JavaScript < FrontCompiler::SourceCode
    module SelfBuilder
      def create_self_build
        rehashed_version = process_hashes_in(self)
        rehashed_version.size > self.size ? self : rehashed_version
      end
      
    protected
    
      def process_hashes_in(string)
        create_build_script *compact_hashes_in(string)
      end
      
      def create_build_script(source, names_map)
        "eval((function(){"+
          "var s=function(){#{source}}.toString().replace(/^\\s*function\\s*\\(\\)\\s*\{/,'').replace(/\\}\\s*;?\\s*$/,'');"+
          "var d={#{names_map.collect{ |k, v| "#{k}:\"#{v}\"" }.join(',')}};"+
          "for(var k in d)"+
            "s=s.replace(new RegExp('((\\\\{|,)\\\\s*)'+k+'(\\\\s*:)','g'),'$1'+d[k]+'$3')"+
               ".replace(new RegExp('(\\\\.)'+k+'([^a-zA-Z0-9_\\\\$\\\\-])','g'),'$1'+d[k]+'$2');"+
          "return s;"+
        "}()));"
      end
      
      def compact_hashes_in(string)
        string = string.dup
        
        names_map = guess_names_map_for(string)
        
        names_map.each do |new_name, old_name|
          string.gsub! /((\{|,)\s*)#{old_name}(\s*:)/ do
            $1 + new_name + $3
          end
          string.gsub! /(\.)#{old_name}([^a-zA-Z0-9_\$\-])/ do
            $1 + new_name + $2
          end
        end
        
        [string, names_map]
      end
      
      def guess_names_map_for(string)
        keys = string.scan(/(\{|,)\s*([a-z_\$][a-z0-9_\$\-]+)\s*:/i).collect(&:last).collect(&:to_s).uniq
        replacements = (1..3).collect{|i| ('a'*i..'z'*i).to_a + ('A'*i..'Z'*i).to_a}.flatten
        
        names_map = {}
        keys.each do |old_name|
          new_name = old_name[/[a-z]/i] || 'a'
          
          while names_map.has_key?(new_name) or 
            string.match(/(\{|,)\s*#{new_name}\s*:/) or
            string.match(/\.#{new_name}[^a-zA-Z0-9_\$\-]/)
            
            new_name = replacements.shift
            break if new_name.nil? # <- safety break if no possible match found
          end
          
          if new_name and new_name.size < old_name.size
            names_map[new_name] = old_name
          end
        end
        
        names_map
      end
      
      def js_native_keys
        
      end
    end
  end
end