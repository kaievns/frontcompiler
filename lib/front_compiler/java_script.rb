#
# This class represents a java-script source code
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#
require "front_compiler/java_script/logic_compactor"
require "front_compiler/java_script/names_compactor"

class FrontCompiler::JavaScript < FrontCompiler::SourceCode
  include LogicCompactor, NamesCompactor
  
  def compact
    string_safely do 
      remove_comments.
        compact_logic.
        compact_names.
        remove_empty_lines.
        remove_trailing_spaces
    end
  end
  
  def remove_comments
    string_safely do 
      gsub!(/\/\*.*?\*\//im, '')
      gsub!(/\/\/.*?($)/, '\1')
    end
  end
  
  def remove_empty_lines
    string_safely do 
      gsub!(/\n\s*\n/m, "\n")
    end
  end
  
  def remove_trailing_spaces
    string_safely do 
      gsub!(/\s+/im, ' ') # cutting down all spaces to the minimum
      gsub!(/\s*(=|\+|\-|<|>|\?|\|\||&&|\!|\{|\}|,|\)|\(|;|\]|\[|:|\*|\/)\s*/im, '\1')
      gsub!(/;(\})/, '\1') # removing unnecessary semicolons
      gsub!(/([^a-z\d_\$]typeof)\s+([a-z\d\$_]+)/im, '\1(\2)') # converting the typeof calls
      strip!
    end
  end
  
protected
  # executes the given block, safely for the strings and regular expressions
  # declared in the source-code
  def string_safely(&block)
    if @in_string_safe_mode
      yield
      return self
    end
    
    outtakes = []
    
    [/(\A|[^\\])('|")(\2)/,                      # <- empty strings
     /(\A|[^\\])('|").*?[^\\](\2)/,              # <- usual strings
     /([^\*\\\/])\/[^\*\/][^\n]*?[^\*\n\\](?!\\\/)\//, # <- regexps
    ].each do |regexp|
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
    
    yield
    
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