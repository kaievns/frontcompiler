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
          "var s=\"#{source.gsub("\\", "\\\\\\\\").gsub("\n", '\\n').gsub('"', '\"').gsub('\\\'', '\\\\\\\\\'')}\","+
          "d={#{names_map.collect{ |k, v| "#{k}:\"#{v}\"" }.join(',')}};"+
          "for(var k in d)"+
            "s=s.replace(new RegExp('((\\\\{|,)\\\\s*)'+k+'(\\\\s*:)','g'),'$1'+d[k]+'$3')"+
               ".replace(new RegExp('(\\\\.)'+k+'([^a-zA-Z0-9_\\\\$])','g'),'$1'+d[k]+'$2');"+
          "return s"+
        "})());"
      end
      
      def compact_hashes_in(string)
        string = string.dup
        
        names_map = guess_names_map_for(string)
        
        names_map.each do |new_name, old_name|
          string.gsub! /((\{|,)\s*)#{old_name}(\s*:)/ do
            $1 + new_name + $3
          end
          string.gsub! /(\.)#{old_name}([^a-zA-Z0-9_\$])/ do
            $1 + new_name + $2
          end
        end
        
        [string, names_map]
      end
      
      def guess_names_map_for(string)
        keys = string.scan(/(\{|,)\s*([a-z_\$][a-z0-9_\$]+)\s*:/i
          ).collect(&:last).collect(&:to_s).concat(js_native_keys(string)).uniq
        replacements = (1..3).collect{|i| ('a'*i..'z'*i).to_a + ('A'*i..'Z'*i).to_a}.flatten
        
        names_map = {}
        keys.each do |old_name|
          new_name = old_name[/[a-z]/i] || 'a'
          
          while names_map.has_key?(new_name) or 
            string.match(/(\{|,)\s*#{new_name}\s*:/) or
            string.match(/\.#{new_name}[^a-zA-Z0-9_\$]/)
            
            new_name = replacements.shift
            break if new_name.nil? # <- safety break if no possible match found
          end
          
          if new_name and new_name.size < old_name.size
            names_map[new_name] = old_name
          end
        end
        
        names_map
      end
      
      def js_native_keys(string)
        JS_NATIVE_KEYS.select do |key|
          # taking only the keys which has more than one entry so it was worth of compacting
          string.scan(/\.#{key}[^a-zA-Z0-9_\$]/).size > 2 
        end
      end
      
    public
      JS_NATIVE_KEYS = %w(
        prototype apply call userAgent toString toSource
        push pop shift unshift length indexOf lastIndexOf select split
        setTimeout setInterval clearTimeout clearInterval
        floor ceil round random
        test match replace toLowerCase toUpperCase substr substring
        parentNode nodeType tagName
        firstChild lastChild childNodes
        nextSibling previousSibling
        appendChild insertBefore replaceChild removeChild
        createElement createTextNode createDocumentFragment 
        getElementById getElementsByTagName
        document body parent opener window
        attachEvent addEventListener
        detachEvent removeEventListener
        getAttribute setAttribute removeAttribute
        checked disabled selected
        id name type title value innerHTML
        style display className defaultView
      ).freeze
    end
  end 
end