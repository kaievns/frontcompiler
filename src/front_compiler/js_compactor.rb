
#
# The JavaScript sources compactor
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#
class FrontCompiler::JSCompactor
  # applies all the compactings to the source
  def minimize(source)
    source = remove_comments(source)
    source = convert_one_line_constructions(source)
    source = remove_empty_lines(source)
    source = remove_trailing_spaces(source)
    
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
  def convert_one_line_constructions(source)
    for_outstrings_of(source) do |str|
      ShortcutsConverter.convert str
    end
  end
  
protected
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
