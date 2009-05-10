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
        # sorting the tokens in order from the longest key to the shortest one
        # so they were not conflicting with each other when the script gets reconstructred
        names_map.sort!{ |a, b| b.split(':').first.size <=> a.split(':').first.size }
        
        "eval((function(){"+
          "var s=\"#{source.gsub("\\", "\\\\\\\\").gsub("\n", '\\n').gsub('"', '\"').gsub('\\\'', '\\\\\\\\\'')}\","+
          
          # building the replacements data
          "d=\"#{names_map.join(',')}\".split(\",\");"+
            
          # building the postprocessing script
          "for(var i=0;i<d.length;i++){p=d[i].split(\":\");"+
            "s=s.replace(new RegExp('#{REPLACEMENTS_PREFIX}'+p[0],'g'),p[1]);}"+
          
          "return s"+
        "})());"
      end
      
      def compact_hashes_in(string)
        string = string.dup
        
        names_map = guess_replacements_map(string, tokens_to_replace_in(string))
        names_map.each do |token|
          new_name, old_name = token.split(':')
          string.gsub! old_name do
            REPLACEMENTS_PREFIX + new_name
          end
        end
        
        [string, names_map]
      end
      
      def tokens_to_replace_in(string)
        # grabbign the basic list of impact tokens
        impact_tokens = get_impact_tokens(string, 
          /(?![^a-z0-9_$])([a-z0-9_$]{#{MINUMUM_REPLACEABLE_TOKEN_SIZE},88})(?![a-z0-9_$])/i)
        
        # getting unprocessed sub-tokens list
        string = string.dup
        impact_tokens.each{ |token| string.gsub! token.split(':').first, '' }
        
        sub_impact_tokens = get_impact_tokens(string, /([A-Z][a-z]{#{MINUMUM_REPLACEABLE_TOKEN_SIZE-1},88})(?![a-z])/)
        
        
        #
        # NOTE: with the optimisation, the sub-tokens should be on the tokens list
        #       after the basic tokens, so they were not affecting each other
        #
        
        # the basic dictionary has some space for new tokens, adding some from the sub-tokens list
        if impact_tokens.size < MAXIMUM_DICTIONARY_SIZE
          sub_tokens = sub_impact_tokens[0, MAXIMUM_DICTIONARY_SIZE - impact_tokens.size]
        else
          # replacing the shortest basic tokens with longest sub-tokens
          sub_tokens = []
          while impact_tokens.last && sub_impact_tokens.first && impact_tokens.last.size < sub_impact_tokens.first.size
            sub_tokens << sub_impact_tokens.shift
            impact_tokens.pop
          end
        end
        
        impact_tokens.concat(sub_tokens)
        
        # grabbing the single tokens back
        impact_tokens.collect{|line| line.split(':').first }
      end
      
      #
      # creates a list of impact-tokens (tokens multiplied to the number of their appearances)
      #
      def get_impact_tokens(string, regexp)
        keys = {}
        
        # scanning through the string and calculating the number of appearances
        string.scan(regexp).collect(&:last).each do |key|
          keys[key] ||= 0
          keys[key] +=  1
        end
        
        # kicking of the tokens which appears less then twice
        keys.reject!{|key,number| number < 2 }
        
        # creating the impact tokens
        tokens = keys.collect do |token, number|
          line = []
          number.times{ line << token }
          line.join(":")
        end
        
        # sorting the tokens by impact
        tokens.sort{|a,b| b.size <=> a.size}[0, MAXIMUM_DICTIONARY_SIZE]
      end
      
      #
      # Generic replacements quessing method
      #
      def guess_replacements_map(string, keys)
        replacements = REPLACEMENTS_CHARS + REPLACEMENTS_CHARS.collect{|c| REPLACEMENTS_CHARS.collect{|a| c+a}}.flatten
        
        map = []
        used_keys = []
        keys.each do |old_name|
          new_name = old_name[/[a-z]/i] || 'a'
          
          while used_keys.include?(new_name) or string.match(/#{REPLACEMENTS_PREFIX}#{new_name}/)
            new_name = replacements.shift
            break if new_name.nil? # <- safety break if no possible match found
          end
          
          # removing the token so the source code was adjusted for the next changes
          string = string.gsub old_name, "#{REPLACEMENTS_PREFIX}#{new_name}"
          
          if new_name and new_name.size < old_name.size
            map << "#{new_name}:#{old_name}"
            used_keys << new_name
          end
        end
        
        map
      end
      
    public
    
      REPLACEMENTS_PREFIX = '@'
      REPLACEMENTS_CHARS  = ('a'..'z').to_a + ('A'..'Z').to_a
      
      MINUMUM_REPLACEABLE_TOKEN_SIZE = 4
      MAXIMUM_DICTIONARY_SIZE        = 150
    end
  end 
end