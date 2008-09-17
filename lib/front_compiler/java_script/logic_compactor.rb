#
# This module contains the javascript logical
# structures processor/compactor
# 
# This module is a part of the JavaScript class and taken out
# just to keep the things simple
# 
# Copyright (C) Nikolay V. Nemshilov aka St.
#
class FrontCompiler
  class JavaScript < FrontCompiler::SourceCode
    module LogicCompactor
      #
      # checks and compacts the script-logic
      #
      def compact_logic
        string_safely do 
          join_multiline_defs
          simplify_constructions_of self
        end
      end
      
    protected
      #
      # joins constructions which split on several lines
      #
      MULTILINING_CHARS_RE = %w{ ? : = - + * / % ! & | < > , 
      }.collect{ |c| Regexp.escape(c)}.join("|")
      def join_multiline_defs
        gsub!(/\s+(#{MULTILINING_CHARS_RE})\s+/m, ' \1 ')
        gsub!(/\s+(#{MULTILINING_CHARS_RE})(\S)/m, ' \1\2')
        gsub!(/(\S)(#{MULTILINING_CHARS_RE})\s+/m, '\1\2 ')
      
        gsub!(/\s*(\.)\s*/m, '\1') # <- fold object member calls
      
        gsub!(/(\()\s+/m, '\1') # <- fold method argument defs
        gsub!(/\s+(\))/m, '\1')
      end
      
      #
      # tries to simplify the short logical constructions
      # which were defined as multilined but could be simplier
      #
      def simplify_constructions_of(src)
        [/(if|for|while)\s*\(/im, /(else|do)\s*\s\{/im].each do |regexp|
          offset = 0
          while pos = src.index(regexp, offset)
            block = name = $1.dup
            block += find_block("()", pos + block.size, src)
            body = find_block("{}", pos + block.size, src)
            
            unless body == ''
              block += body[/\A\s*/m]; body.strip! # removing starting empty-chars
              body_code = body[1, body.size-2]
              
              # checking if the code can be simplified
              can_be_simplified = number_of_code_lines_in(body_code) == 1
              
              # check additional 'if' constructions restrictions
              if can_be_simplified and name == 'if'
                # double ifs construction check
                can_be_simplified &= !body_code.match(/\A\s*if\s*\(/im)
                
                # checking the else blocks missintersections
                if src[pos+block.size+body.size, 40].match(/\A\s*else(\s+|\{)/)
                  can_be_simplified &= !body_code.match(/(\A|[^a-z\d_$])if\s*\(/)
                end
              end
              
              # try to simplify internal constructions
              simplify_constructions_of body_code
              
              if can_be_simplified
                check_semicolons_in body_code
              else
                body_code = "{#{body_code}}"
              end
              
              src[pos+block.size, body.size] = body_code
              body = body_code
            end
            
            offset = pos + block.size + body.size
          end
        end
        
        # removing bugy semicolons
        src.gsub!(/(\}\s*);(\s*else\s+)/, '\1\2')
      end
      
      # calculates the number of code-lines in the string
      def number_of_code_lines_in(src)
        src = src.dup
        
        # replacing all the method calls, blocks and lists with dummies
        ['[]', '()', '{}'].each do |pair|
          offset = 0
          while pos = src.index(pair[0,1], offset)
            offset = pos + 1
            block = find_block(pair, 0, src[pos, src.size])
            
            src[pos, block.size] = pair
          end
        end
        
        # putting semicolons after try/catch/finally constructions, so they were conuted as well
        src.gsub!(/(catch\s*\(\)|finally)\s*\{\}/, '\&;')
        
        # calculating the number of the lines
        src.split(';').collect{ |line|
          line.strip != '' ? 1 : nil
        }.compact.size
      end
    end
    
    # checks if there's ommited semicolons in the code
    def check_semicolons_in(src)
      src[/\s*\Z/m] = ";#{src[/\s*\Z/m]}" unless src.strip[-1,1].match(/[;\}]/)
    end
  end
end
