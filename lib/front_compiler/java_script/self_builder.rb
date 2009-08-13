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
        "eval((function(s,d){"+
          # building the postprocessing script
          "for(var i=d.length-1;i>-1;i--)"+
            "if(d[i])"+
              "s=s.replace(new RegExp(i,'g'),d[i]);"+
          "return s"+
        "})("+
          "\"#{source.gsub("\\", "\\\\\\\\").gsub("\n", '\\n').gsub('"', '\"').gsub('\\\'', '\\\\\\\\\'')}\","+
          "\"#{names_map.join(',')}\".split(\",\")"+
        "));"
      end
      
      def compact_hashes_in(string)
        string = string.dup
        
        names_map = guess_replacements_map(string, tokens_to_replace_in(string))
        
        names_map.each_with_index do |token, i|
          string.gsub! token, "#{i}" if token != ''
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
        map = []
        index = -1
        keys.each do |old_name|
          index += 1
          
          while string.match(/#{index}/)
            map << ''
            index+= 1
          end
          
          map << old_name
          
          string = string.gsub old_name, "#{index}"
        end
        
        map
      end
      
    public
    
      MINUMUM_REPLACEABLE_TOKEN_SIZE = 3
      MAXIMUM_DICTIONARY_SIZE        = 150
    end
  end 
end