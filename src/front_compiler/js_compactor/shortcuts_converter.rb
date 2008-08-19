#
# This stuff converts the javascript conditions shortcuts
# like
#
# if (something()) return false;
#
# to more wellformed constructions like
#
# if (something()){ return false;}
#
# so the code could get properly compacted in a single
# string on the later compacting stages
#
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#
class FrontCompiler::JSCompactor::ShortcutsConverter
  class << self
    # converts shortcuts in the string
    def convert(str)
      str = str.gsub /((if|for|while)\s*\().*/im do |match|
        construction, stack = find_construction(match.to_s)
        stack = convert(stack) # <- serach for constructions
        construction + stack
      end
      
      # convert the else's single line constructions
      str = str.gsub /((\}|\s)else\s*)[^\{]+.*/im do |match|
        start = $1.dup
        stack = match.to_s[start.size, match.to_s.size]
        
        # converting the nested constructions
        if stack =~ /\A\s*(if|for|while)\s*\(/im
          body, stack = find_construction(stack)
          start += "{#{body}}"
          
          # converting a simple single-line case.
        elsif body = stack[/\A\s*.+?\n/im]
          body = body[0, body.size-1] # <- skip the last new line
          stack = stack[body.size, stack.size]
          start += body =~ /\A\s*\{/ ? body : "{#{body}}"
        end
        
        "#{start}#{stack}"
      end
    end
    
  protected
    # takes a string, finds a construction
    # returns a list, the construction string and rest of the string
    def find_construction(string)
      conditions = string[/\s*(if|for|while)\s*\(/im]
      conditions = conditions[0, conditions.size-1]
      conditions+= find_block(string[conditions.size, string.size], "(")
      
      stack = string[conditions.size, string.size]
      
      if stack =~ /\A\s*\{/im
        # find the end of the construction
        body = find_block(stack, "{")
        stack = stack[body.size, stack.size]
        
      elsif stack =~ /\A\s*(if|for|while)\s*\(/im
        # nesting
        body, stack = find_construction(stack)
        
      elsif body = stack[/\A\s*.+?\n/im]
        body = body[0, body.size-1] # <- skip the last new line
        stack = stack[body.size, stack.size]
      else
        body = ''
      end
      
      body = "{#{body}}" unless body =~ /\A\s*\{/ # filters out doublequoting
      
      ["#{conditions}#{body}", stack]
    end
    
    # searches for a block in the stack
    def find_block(stack, left="(")
      @@BLOCK_CHUNKS ||= { "(" => ")", "{" => "}", "[" => "]" }
      right = @@BLOCK_CHUNKS[left]
      block = stack[/\A\s*#{Regexp.escape(left)}/im]
      stack = stack[block.size, stack.size].split('')
      
      count = 0
      while char = stack.shift
        block << char
        
        if char == right and count == 0
          break
        else
          count += 1 if char == left
          count -= 1 if char == right
        end
      end
      
      block
    end
  end
end
