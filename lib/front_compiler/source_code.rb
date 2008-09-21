#
# That's all the source-codes base class
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#
class FrontCompiler::SourceCode < String
  def initialize(src)
    super src
  end
  
  # returns a fully compacted source
  def compact!
    remove_comments!.
      remove_empty_lines!.
      remove_trailing_spaces!
  end
  
  # removes any comments
  def remove_comments!
    self
  end
  
  # removes empty lines
  def remove_empty_lines!
    self
  end
  
  # removes all the trailing spaces
  def remove_trailing_spaces!
    self
  end
  
  alias :compact :compact!

protected
  # executes the given block, safely for the strings declared in the source-code
  # can apply a list of additional regexps to escape
  def string_safely(additional_regexps=[], &block)
    if @in_string_safe_mode
      yield
      return self
    end
    
    outtakes = []
    
    [/(\A|[^\\])('|")(\2)/,            # <- empty strings
     /(\A|[^\\])('|").*?[^\\](\2)/     # <- usual strings
    ].concat(additional_regexps).each do |regexp|
      gsub! regexp do |match|
        replacement = "rIgAxpOrStrEEng$$$#{outtakes.length}$$$riPlOcImEnt"
        start = $1.dup
        outtakes << { 
          :replacement => replacement, 
          :original    => match.to_s[start.size, match.to_s.size]
        }
        
        start + replacement
      end
    end
    @in_string_safe_mode = true
    
    yield block
    
    # bgingin the strings back
    outtakes.reverse.each do |s|
      gsub! s[:replacement], s[:original].gsub('\\','\\\\\\\\') # <- escapes reescaping
    end
    @in_string_safe_mode = false
    
    self
  end
  
  # searches for a block in the code which starts at the given position
  BLOCK_CHUNKS = {"()" => ["(",")"], "{}" => ["{","}"], "[]" => ["[","]"]}
  def find_block(like, offset=0, stack=nil)
    left, right = BLOCK_CHUNKS[like]
    src = stack || self
    start_pos = src.index(left, offset)
    
    # return an empty string if the left sign was not found or fount not at the beginning
    return '' if start_pos.nil? or !src[offset, start_pos-offset].match(/\A\s*?\Z/im)
    
    start_pos += 1 # <- include the left sign to the block
    block = src[offset, start_pos-offset]
    
    count = 0
    (start_pos...src.size).each do |i|
      char = src.slice(i,1)
      
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