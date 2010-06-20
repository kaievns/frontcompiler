#
# This module contains the names compactor functionality
# 
# This module is a part of the JavaScript class and taken out
# just to keep the things simple
# 
# Copyright (C) 2008-2010 Nikolay Nemshilov
#
class FrontCompiler
  class JavaScript < FrontCompiler::SourceCode
    module NamesCompactor
      def compact_names!
        string_safely do 
          compact_names_of self
        end
      end
      
    protected
      FUNCTION_START_RE = %r{
          (\A|[^\da-z_\$])    # ensure this is not a weird method name
          function(\s
            ([a-z\d\$_]+)     # function name
          )*\s*\(
          ([a-z\d\\$\s_,]*)   # arguments list
          \)\s*               # end of the function definition
      }imx
      
      def compact_names_of(src)
        offset = 0
        while pos = src.index(FUNCTION_START_RE, offset)
          func_start = $&.dup
          args_block = $4.dup
          body_block = find_block("{}", pos + func_start.size, src)
          
          args, body = process_names(args_block, compact_names_of(body_block.dup))
          func = func_start.gsub "(#{args_block})", "(#{args})"
          
          src[pos, func_start.size + body_block.size] = func + body
          
          offset = pos + func.size + body.size
        end
        
        src
      end
      
      # handles the names processing
      def process_names(args, body)
        args = args.dup  # <- duplicating the string case they will be parsed
        body = body.dup
        
        # building the names replacement map
        guess_names_map(body,
          find_body_varnames(body).select{ |n| n.size > 1
          }.concat(args.scan(/[\w\d_\$]+/im)
          ).uniq.sort.select{ |n| n != '$super' } # <- escape the Prototype stuff
        ).each do |name, replacement|
          # replacing the names
          [args, body].each do |str|
            str.gsub!(/(\A|[^\w\d_\.\$])#{Regexp.escape(name)}(?![\w\d_\$]|\s*:)/) do
              $1 + replacement
            end
            
            # replacing the names in the short 'a ? b : c' conditions
            str.gsub!(/([^\{,\s\w\d_\.\$]\s*)#{Regexp.escape(name)}(\s*?:)/) do
              $1 + replacement + $2
            end
          end
        end
        
        [args, body]
      end
      
      # makes decisions about the names cutting down
      def guess_names_map(body, names)
        names_map = { }
        used_renames = []
        
        @replacements ||= ('a'...'z').to_a.concat(('A'...'Z').to_a)
#          concat(('aa'...'zz').to_a).
#          concat(('a'...'z').collect{ |c| ('A'...'Z').collect{|n| c + n}}.flatten.
#          concat(('A'...'Z').collect{|c| ('a'...'z').collect{|n| c+ n}})).flatten  .
#          concat(('AA'...'ZZ').to_a)
        
        names.each do |name|
          [name[/[a-z]/i]||'a'].concat(@replacements).each do |rename|
            if !used_renames.include?(rename) and !body.match(/[^\w\d_\.\$]#{rename}[^\w\d_\$]/)
              names_map[name] = rename
              used_renames << rename
              break
            end
          end
        end
        
        names_map
      end
      
      # extracts localy defined varnames of the given function body block
      def find_body_varnames(body)
        # getting the body body
        body = body[1, body.size-2]
        
        names = []
        
        # removing the internal functions
        while pos = body.index(FUNCTION_START_RE)
          func = $&.dup
          
          func_name = $3 ? $3.dup : ''
          names << func_name unless func_name == ''
          
          body[pos+1, func.size-1+find_block("{}", pos+func.size, body).size] = ''
        end
        
        # removing functions calls blocks
        offset = 0
        while pos = body.index(/[a-z0-9_]\(/i, offset)
          pos += 1
          block = find_block("()", pos, body)
          body[pos, block.size] = '' unless body[0, pos].match(/(if|for|while|catch)\s*\Z/im)
          
          offset = pos + 1
        end
        
        # getting the vars definitions
        body.scan(/[\s\(:;=\{\[^$]+var\s(.*?)(;|\Z)/im) do |match|
          line = $1.dup
          
          # removing arrays and objects definitions out of the line
          ['[]', '{}'].each do |token|
            offset = 0
            while pos = line.index(token=='[]' ? /\[.*?\]/ : /\{.*?\}/, offset)
              pos += 1
              block = find_block(token, pos, line)
              line[pos, block.size] = ''
              
              offset = pos + 1
            end
          end
          
          
          # removing objects definitions
          
          names.concat(line.split(",").collect{ |token|
              token[/[\w\d_\$]+/i]
            }.compact)
        end
        
        names
      end
    end
  end
end