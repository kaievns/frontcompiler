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
#        rehashed_version.size > self.size ? self : rehashed_version
      end
      
    protected
    
      def process_hashes_in(string)
        create_build_script *compact_hashes_in(string)
      end
      
      def create_build_script(source, maps)
        "eval((function(){"+
          "var s=\"#{source.gsub("\\", "\\\\\\\\").gsub("\n", '\\n').gsub('"', '\"').gsub('\\\'', '\\\\\\\\\'')}\","+
          
          # building the replacements data
          "d={#{maps.collect{ |k, v| "#{k}:\"#{v}\"" }.join(',')}};"+
            
          # building the postprocessing script
          "for(var k in d)"+
            "s=s.replace(new RegExp('#{REPLACEMENTS_PREFIX}'+k,'g'),d[k]);"+
          
          "return s"+
        "})());"
      end
      
      def compact_hashes_in(string)
        compress_string(string, [
          [:guess_names_map_for, :js_hash_key_re, :js_hash_use_re],
          [:guess_structs_map_for, :js_structs_re],
          [:guess_commands_map_for, :js_commands_re],
          [:guess_objects_map_for, :js_objects_re]
        ])
      end
      
      #
      # Guesses the names map to shortify hashes keys in the source code
      #
      def guess_names_map_for(string)
        keys = string.scan(/(\{|,)\s*([a-z_\$][a-z0-9_\$]+)\s*:/i).collect(&:last).collect(&:to_s)
        keys = worth_of_replace(keys+JS_NATIVE_KEYS, string){|name| js_hash_use_re(name)}
        
        guess_replacements_map(string, keys.uniq) do |name|
          [js_hash_key_re(name), js_hash_use_re(name)]
        end
      end
      
      def js_hash_key_re(name)
        /([\{,]\s*)#{name}(\s*:)/
      end
      
      def js_hash_use_re(name)
        /(\.)#{name}([^a-zA-Z0-9_\$])/
      end
      
      #
      # Guesses the replacements map for the standard constructions like
      #  function (), switch (), while ()
      #
      def guess_structs_map_for(string)
        keys = worth_of_replace(JS_STRUCTS, string){|name| js_structs_re(name)}
        
        guess_replacements_map(string, keys) do |name|
          [js_structs_re(name)]
        end
      end
      
      def js_structs_re(name)
        /([^a-zA-Z0-9_\$])#{name}((\s*|(\s+[a-zA-Z0-9_\$]+\s*))\()/
      end
      
      #
      # guesses the replacements map for the commands like return, throw, catc etc.
      #
      def guess_commands_map_for(string)
        keys = worth_of_replace(JS_COMMANDS, string) {|name| js_commands_re(name)}
        
        guess_replacements_map(string, keys) do |name|
          [js_commands_re(name)]
        end
      end
      
      def js_commands_re(name)
        /([^a-zA-Z0-9_\$])#{name}([^a-zA-Z0-9_\$])/
      end
      
      
      #
      # guesses the replacements map for the javascript often used objects
      #
      def guess_objects_map_for(string)
        keys = worth_of_replace(JS_OBJECTS, string){ |name| js_objects_re(name) }
        
        guess_replacements_map(string, keys) do |name|
          [js_objects_re(name)]
        end
      end
      
      def js_objects_re(name)
        /([^a-zA-Z0-9_\$])#{name}(\.)/
      end
      
      #
      # checks which of the given keys are used enough to be compressed
      #
      def worth_of_replace(keys, string, &block)
        keys.select do |name|
          string.scan(yield(name)).size >= MINIMUM_NUMBER_OF_APPEARANCES
        end
      end
      
      #
      # Generic replacements quessing method
      #
      def guess_replacements_map(string, keys, &block)
        map = {}
        keys.each do |old_name|
          new_name = old_name[/[a-z]{2}/i] || 'aa'
          
          while map.has_key?(new_name) or string.match(/#{REPLACEMENTS_PREFIX}#{new_name}/)
            new_name = REPLACEMENTS.shift
            break if new_name.nil? # <- safety break if no possible match found
          end
          
          if new_name and new_name.size < old_name.size
            map[new_name] = old_name
          end
        end
        
        map
      end
      
      REPLACEMENTS = [2].collect{|i| ('a'*i..'z'*i).to_a + ('A'*i..'Z'*i).to_a}.flatten.sort_by(&:size)
      REPLACEMENTS_PREFIX = '@'
      
      #
      # Handles the source code remaping
      #
      def compress_string(string, replacements)
        string = string.dup
        maps = {}
        
        replacements.each do |options|
          map = send(options.shift, string)
          map.each do |new_name, old_name|
            options.each do |re_method|
              string.gsub! send(re_method, old_name) do
                $1 + REPLACEMENTS_PREFIX + new_name + $2
              end
            end
          end
          
          maps.merge!(map)
        end
        
        [string, maps]
      end
      
    public
      
      MINIMUM_NUMBER_OF_APPEARANCES = 2
      
      JS_NATIVE_KEYS = %w(
        prototype constructor apply call userAgent toString toSource
        push pop shift unshift length indexOf lastIndexOf select split slice
        setTimeout setInterval clearTimeout clearInterval
        floor ceil round random
        test match replace toLowerCase toUpperCase substr substring charAt charCodeAt fromCharCode
        parentNode firstChild lastChild childNodes nextSibling previousSibling
        nodeType nodeValue tagName appendChild insertBefore replaceChild removeChild
        createElement createTextNode createDocumentFragment 
        getElementById getElementsByTagName
        document body parent opener window
        attachEvent addEventListener
        detachEvent removeEventListener
        getAttribute setAttribute removeAttribute
        offsetHeight offsetWidth offsetTop
        checked disabled selected
        name type title value innerHTML responseText responseXML
        style display className defaultView
      ).freeze
      
      JS_STRUCTS = %w(
        function switch while
      ).freeze
      
      JS_COMMANDS = %w(
        return break continue default true false catch finally throw arguments case instanceof typeof
        encodeURIComponent decodeURIComponent escape unescape null
      ).freeze
      
      JS_OBJECTS = %w(
        document window this self navigator Object String Array Date RegExp Element Prototype
      ).freeze
    end
  end 
end