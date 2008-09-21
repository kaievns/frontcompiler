#
# This module contains the nested css handling
# it converts virtual nested css constructions to standard css constructions
# 
# Copyright (C) Nikolay V. Nemshilov aka St.
#
class FrontCompiler
  class FrontCompiler::CssSource < FrontCompiler::SourceCode
    module NestedStyles
      # overloads the constructor, to convert the styles on fly
      def initialize(src, keep_as_is=false)
        super src
        convert_nested_styles! unless keep_as_is
      end
      
      # converts the nested styles constructions in the source
      CSS_CONSTRUCTION_RE = /((\A|\}|;)\s*?([^\}\{;]+?)\s*?)\{.*?\}/m
      def convert_nested_styles!
        # loop though the blocks
        offset = 0
        while pos = index(CSS_CONSTRUCTION_RE, offset)
          pos += $1.size # <- getting the actual block position
          block = find_block("{}", pos)
          block = block[1, block.size-1]; pos+=1 # <- remove the container
          block_size = block.size
          
          parent_rules = clean_rules_from $3 # <- the block rules list

          block_sub_styles = []
          
          # looking for a nested construction
          while block_pos = block.index(CSS_CONSTRUCTION_RE)
            trail_char = $2.dup
            
            block_start = $1.dup
            block_start = block_start[trail_char.size, block_start.size]
            block_start_size = block_start.size
            
            block_pos += trail_char.size # <- updating the sub-block position
            
            # update the sub-bolock rules
            clean_rules_from($3).each do |block_rule|
              block_start.gsub! block_rule, parent_rules.collect{ |p_rule|
                "#{p_rule} #{block_rule}"
              }.join(", ")
            end
            
            # getting the construction body
            block_body = find_block("{}", block_pos + block_start_size, block)
            
            # removing the construction out of the block
            block[block_pos, block_start_size + block_body.size] = ''
            block_sub_styles << block_start + block_body
          end
          
          # replacing the block
          self[pos, block_size] = block + block_sub_styles.join('')
          
          offset = pos + block.size - 1
        end
      end
      
    protected  
      # creates a clean css-rules list out of the str
      def clean_rules_from(str)
        str.split(',').collect{ |rule|
          rule.gsub(/\s+/, ' ').gsub(/\/\*.*?\*\//im, '').strip
        }
      end
    end
  end
end