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
      
      # removing wrongly added semicolons
      str.gsub! /([^a-z\d_$\.]else);/im, '\1'
      
      offset = 0
      while pos = (str.index(/(if|for|while|function)\s*\(/im, offset))
        offset = pos + 1
        
        start = str[0, pos]
        stack = str[pos, str.size]
        
        start+= stack[/\A(if|for|while|function)\s*/im]
        stack = str[start.size, str.size]
        
        start+= find_block(stack, '(')
        stack = str[start.size, str.size]
        
        stack = stack[1, stack.size] if stack[0,1] == ';'
        
        str = start + stack
      end
      
      str
    end
  end
end
