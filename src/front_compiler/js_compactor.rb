#
# The JavaScript sources compactor
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#
class FrontCompiler::JSCompactor
  # applies all the compactings to the source
  def minimize(source)
    source = remove_comments(source)
    source = compact_local_names(source)
#    source = remove_empty_lines(source)
    source = remove_trailing_spaces(source)
    
    source.strip
  end
  
  # removes all the comments out of the source code
  def remove_comments(source)
    for_outstrings_of(source) do |str|
      str.gsub! /\/\*.*?\*\//im, ''
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
      str.gsub! /\s+/im, ' '
      str.gsub! /\s*(=|\+|\-|<|>|\?|\|\||&&|\!|\{|\}|,|\)|\(|;|\]|\[|:|\*|\/)\s*/im, '\1'
      str.gsub! /;(\]|\)|\}|\.|\?|:)/, '\1' # removing wrong added semicolons
      str.gsub  /([^\d\w_\$]typeof)\s+([\w\d\$_]+)/, '\1(\2)'
    end
  end
  
  # compacts the local names of the functions in the source code
  def compact_local_names(source)
    for_outstrings_of(source) do |str|
      NamesCompactor.compact str
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
    strings = []
    
    # preserving the regular expressions
    str = str.gsub /([^\*\\\/])\/[^\*\/].*?[^\\\*\/]\// do |match|
      replacement = "rIgAxp$%#{strings.length}$%riPlOcImEnt"
      start = $1.dup
      strings << { 
        :replacement => replacement, 
        :original    => match.to_s[start.size, match.to_s.size]
      }
      
      start + replacement
    end
    
    # preserving the string definitions
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
