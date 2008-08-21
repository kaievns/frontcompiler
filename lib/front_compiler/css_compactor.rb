#
# The CSS sources compactor
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#
class FrontCompiler::CSSCompactor
  # applies all the compactings to the given source
  def minimize(source)
    source = remove_comments(source)
    source = remove_trailing_spaces(source)
  end
  
  # converts the source in such a way that it could be
  # delivered with javascript in the same file
  def to_javascript(source)
    "document.write(\"<style type=\\\"text/css\\\">#{
       minimize(source).gsub('"', '\"')
     }</style>\");"
  end
  
  # removes all the comments out of the given source
  def remove_comments(source)
    for_outstrings_of(source) do |str|
      str.gsub! /\/\*.*?\*\//im, ''
      str
    end
  end
  
  # removes all the empty lines out of the source code
  def remove_empty_lines(source)
    for_outstrings_of(source) do |str|
      str.gsub /\n\s*\n/m, "\n"
    end
  end
  
  # removes tailing whitespaces out of the source code
  def remove_trailing_spaces(source)
    for_outstrings_of(source) do |str|
      str.gsub! /\s+/im, ' '
      str.gsub! /\s*(\+|>|\||~|\{|\}|,|\)|\(|;|:|\*)\s*/im, '\1'
      str.gsub! /;\}/, '}'
      str.strip
    end
  end
  
protected
  # escapes all the strings defined in the source
  # and get everything back after processing
  # to keep the strings safe
  def for_outstrings_of(str, &block)
    strings = []
    
    str = str.gsub /('|").*?[^\\](\1)/ do |match|
      replacement = "sfTEEg$%#{strings.length}$%riPlOcImEnt"
      strings << { 
        :replacement => replacement, 
        :original    => match.to_s
      }
      
      replacement
    end
    
    # running the handler
    str = yield(str)
    
    # bgingin the strings back
    strings.reverse.each do |s|
      str.gsub! s[:replacement], s[:original].gsub('\\','\\\\\\\\')
    end
    
    str
  end
end
