#
# FrontCompiler, the only and main unit of the library
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#

class FrontCompiler
  attr_reader :js
  
  def initialize
    @js = JSCompactor.new
  end
  
  def compact_dir(dir)
  end
  
  def compact_files(list)
  end
  
  def compact_file(file)
    file = File.open(file) if file.is_a?(String)
    
    
    y file.name
    compact_js file.read
  end
  
  def compact_js(source)
    @js.minimize(source)
  end
  
  def compact_css(source)
    source
  end
  
  def compact_html(source)
    
  end
  
  #
  # The JavaScript sources compactor
  #
  class JSCompactor
    # applies all the compactings to the source
    def minimize(source)
      source = @js.remove_comments(source)
      source = @js.convert_one_line_cnstructions(source)
      source = @js.remove_empty_lines(source)
      source = @js.remove_trailing_spaces(source)
      
      source.trim
    end
    
    # removes all the comments out of the source code
    def remove_comments(source)
      for_outstrings_of(source) do |str|
        str.gsub! /\/\*.*?\*\//m, ''
        str.gsub! /\/\/.*?$/, ''
        str
      end
    end
    
    # removes empty lines out of the source code
    def remove_empty_lines(source)
      for_outstrings_of(source) do |str|
        str.gsub /\n\s*\n/m, "\n"
      end
    end
    
    # removes all the trailing spaces out of the code
    def remove_trailing_spaces(source)
      for_outstrings_of(source) do |str|
        str.gsub /\s*(=|\+|\-|<|>|\?|\|\||&&|\!|\{|\}|,|\)|\(|;|\]|\[|:|\*)\s*/im, '\1'
      end
    end
    
    # converts the one line if/for/while constructions 
    # into multilined ones
    def convert_one_line_cnstructions(source)
      for_outstrings_of(source) do |str|
        str = str.gsub /((if|for|while)\s*\().*/im do |match|
          construction, stack = find_construction(match.to_s)
          stack = convert_one_line_cnstructions(stack) # <- serach for constructions
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
      
      body = "{#{body}}" unless body =~ /\A\s*\{/
      
      ["#{conditions}#{body}", stack]
    end
    
    BLOCK_CHUNKS = { 
      "(" => ")",
      "{" => "}",
      "[" => "]"
    }
    # searches for a block in the stack
    def find_block(stack, left="(")
      right = BLOCK_CHUNKS[left]
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
    
    
    #
    # executes the given block on the incomming string
    # but keeping the strings safe
    #
    def for_outstrings_of(str, &block)
      # preserving the string definitions
      strings = []
      src = str.gsub /('|").*?[^\\](\1)/mx do |match|
        replacement = "string$%#{strings.length}$%replacement"
        strings << { 
          :replacement => replacement, 
          :original    => match.to_s
        }
        
        replacement
      end
      
      # running the handler
      src = yield(src)
      
      # bgingin the strings back
      strings.each do |s|
        src.gsub! s[:replacement], s[:original]
      end
      
      src
    end
  end
end
