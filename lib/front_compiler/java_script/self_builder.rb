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
          
          # building the replacements data
          "d=\"#{names_map.collect{ |k, v| "#{k}:#{v}" }.join(',')}\".split(\",\");"+
            
          # building the postprocessing script
          "for(var i=0;i<d.length;i++){p=d[i].split(\":\");"+
            "s=s.replace(new RegExp('#{REPLACEMENTS_PREFIX}'+p[0]+'([^a-zA-Z0-9_$])','g'),p[1]+'$1');}"+
          
          "return s"+
        "})());"
      end
      
      def compact_hashes_in(string)
        string = string.dup
        
        names_map = guess_replacements_map(string, tokens_to_replace_in(string))
        names_map.each do |new_name, old_name|
          string.gsub! /([^a-zA-Z0-9_\$])#{old_name}([^a-zA-Z0-9_\$])/ do
            $1 + REPLACEMENTS_PREFIX + new_name + $2
          end
        end
        
        [string, names_map]
      end
      
      def tokens_to_replace_in(string)
        keys = {}
        
        # getting the list of all the tokens of a good size
        string.scan(/(?![^a-z0-9_$])([a-z0-9_$]{#{MINUMUM_REPLACEABLE_TOKEN_SIZE},88})(?![a-z0-9_$])/i
        ).collect(&:last).each do |key|
          keys[key] ||= 0
          keys[key] +=  1
        end
        
        # filtering by the number of its appearances in the code
        keys.reject! do |key, number|
          number < self.class.minum_number_of_entry_appearances
        end
        
        # converting the list to an array of tokens ordered by the number of appearances
        keys.collect{|k,v| m={}; m[v] = k; m}.sort{|a,b| b.first <=> a.first}.collect(&:values).collect(&:first)
      end
      
      #
      # Generic replacements quessing method
      #
      def guess_replacements_map(string, keys)
        replacements = REPLACEMENTS_CHARS + REPLACEMENTS_CHARS.collect{|c| REPLACEMENTS_CHARS.collect{|a| c+a}}.flatten
        map = {}
        keys.each do |old_name|
          new_name = old_name[/[a-z]/i] || 'a'
          
          while map.has_key?(new_name) or string.match(/#{REPLACEMENTS_PREFIX}#{new_name}/)
            new_name = replacements.shift
            break if new_name.nil? # <- safety break if no possible match found
          end
          
          if new_name and new_name.size < old_name.size
            map[new_name] = old_name
          end
        end
        
        map
      end
      
    public
      module ClassMethods
        def minum_number_of_entry_appearances
          @@minum_number_of_entry_appearances ||= MINIMUM_NUMBER_OF_APPEARANCES
        end

        def minum_number_of_entry_appearances=(number)
          @@minum_number_of_entry_appearances = number
        end
      end
      
      def self.included(base)
        base.instance_eval{ extend ClassMethods }
      end
    
      REPLACEMENTS_PREFIX = '@'
      REPLACEMENTS_CHARS  = ('a'..'z').to_a + ('A'..'Z').to_a
      
      MINUMUM_REPLACEABLE_TOKEN_SIZE = 4
      MINIMUM_NUMBER_OF_APPEARANCES  = 8
    end
  end 
end