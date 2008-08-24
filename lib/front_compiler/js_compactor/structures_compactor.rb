#
# This module compacts the logical structures
# joins definitions which were on several lines in
# single lines, converts logic in shortcuts where possible
# puts forgotten semicolons, etc.
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#
class FrontCompiler::JSCompactor::StructuresCompactor
  extend FrontCompiler::JSCompactor::Util
  
  # all the methods of the class are static
  class << self
    
    # the front method
    def compact(str)
      str = join_multilined_defs(str)
      str = insert_omitted_semicolons(str)
      str = simplify_logical_constructions(str)
      str
    end
    
  protected
    # joins multilined definitions
    def join_multilined_defs(str)
      chars = %w{ ? : = - + * / % ! & | < > , }
      chars = chars.collect{ |c| Regexp.escape(c)}.join("|")
      
      str.gsub! /\s+(#{chars})\s+/m, ' \1 '
      str.gsub! /\s+(#{chars})(\S)/m, ' \1\2'
      str.gsub!  /(\S)(#{chars})\s+/m, '\1\2 '
      
      str.gsub! /\s*(\.)\s*/m, '\1'
      
      str.gsub! /(\()\s+/m, '\1'
      str.gsub! /\s+(\))/m, '\1'
      
      str
    end
    
    # inserts omitted semicolons
    def insert_omitted_semicolons(str)
      str.gsub! /([^\s;\(\[\{\A])(\s*?\n)/m do |match|
        "#{$1};#{$2}"
      end
      str.gsub! /([^\s;\A])(\s*\Z)/m, '\1;\2'
      
      # removing wrongly added somicolons at logical expressions
      offset = 0
      while pos = str.index(/(if|for|while)\s*\(/im, offset)
        offset = pos + 1
        
        start = str[0, pos]
        stack = str[pos, str.size]
        
        start+= stack[/\A(if|for|while)\s*/im]
        stack = str[start.size, str.size]
        
        start+= find_block(stack, '(')
        stack = str[start.size, str.size]
        
        stack = stack[1, stack.size] if stack[0,1] == ';'
        
        # removing semicolons after the logic bodies
        if stack =~ /\A\s*?\{/
          start += stack[/\A\s*/]
          stack = str[start.size, str.size]
          
          block = find_block(stack, '{')
          stack = stack[block.size, stack.size]
          
          stack = stack[1, stack.size] if stack[0,1] == ';'
          
          start+= "{"+insert_omitted_semicolons(block[1, block.size-2])+"}"
        end
        
        str = start + stack
      end
      
      # removing wrongly added semicolons at 'else' constructions
      str.gsub! /([^a-z\d_$\.]else);/im, '\1'
      offset = 0
      while pos = str.index(/else\s*?\{/im, offset)
        offset = pos+1
        start = str[0, pos]
        stack = str[pos, str.size]
        
        start+= stack[/\Aelse\s*/im]
        stack = str[start.size, stack.size]
        
        block = find_block(stack, '{')
        stack = stack[block.size, stack.size]
        
        stack = stack[1, stack.size] if stack[0,1] == ';'
        
        start+= "{"+insert_omitted_semicolons(block[1, block.size-2])+"}"
        
        str = start + stack
      end
      
      str
    end
    
    # converts simple mutli-lined logical constructions
    # to short single-lined constructions
    def simplify_logical_constructions(str)
      # checking the if/for/while constructions
      if pos = str.index(/(if|for|while)\s*\(/im)
        start = str[0, pos]
        stack = str[pos, str.size]
        
        # cutdown the method name
        start+= stack[/\A(if|for|while)\s*/im]
        stack = str[start.size, str.size]
        
        # cutdown the logic conditions
        start+= find_block(stack, '(')
        stack = str[start.size, str.size]
        
        # getting the logic block
        if stack =~ /\A\s*?\{/
          start += stack[/\A\s*/]
          stack = str[start.size, str.size]
          
          # join back the string
          str = start + check_first_block_of(stack)
        end
      end
      
      # check the 'else {...}' constructions
      if pos = str.index(/else\s*?\{/im)
        start = str[0, pos]
        stack = str[pos, str.size]
        
        start += stack[/\Aelse\s*/im]
        stack = str[start.size, str.size]
        
        str = start + check_first_block_of(stack)
      end
      
      str
    end
    
  private
    # checks the first block of the stack
    def check_first_block_of(stack)
      block = find_block(stack, '{')
      stack = stack[block.size, stack.size]
      
      # checking the number of code-lines in the block
      block_code = block[1, block.size-2]
      if number_of_code_lines_in(block_code) == 1
        block = block_code
      end
      
      # recoursive call on the rest of the stack
      simplify_logical_constructions(block) + 
        simplify_logical_constructions(stack)
    end
    
    # checks the number of code lines in the string
    def number_of_code_lines_in(str)
      str = str.dup
      
      # removing all the method calls, blocks and lists
      ['[', '(', '{'].each do |token|
        offset = 0
        while pos = str.index(token, offset)
          offset = pos + 1
          start = str[0, pos]
          stack = str[pos, str.size]
          block = find_block(stack, token)
          
          str.gsub! block, case token
                             when '(' then '()'
                             when '[' then '[]'
                             else ';'
                           end
        end
      end
      
      number = 0
      
      # calculating the number of the lines
      str.split(';').each do |line|
        number+=1 if line.strip != ''
      end
      
      number
    end
  end
end
