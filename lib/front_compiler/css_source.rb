#
# The CSS sources compactor
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#
require "front_compiler/css_source/nesting"
class FrontCompiler::CssSource < FrontCompiler::SourceCode
  include Nesting
  
  # removes all the comments out of the given source
  def remove_comments
    string_safely do 
      gsub!(/\/\*.*?\*\//im, '')
    end
  end
  
  # removes all the empty lines out of the source code
  def remove_empty_lines
    string_safely do
      gsub!(/\n\s*\n/m, "\n")
    end
  end
  
  # removes tailing whitespaces out of the source code
  def remove_trailing_spaces
    string_safely do
      gsub!(/\s+/im, ' ')
      gsub!(/\s*(\+|>|\||~|\{|\}|,|\)|\(|;|:|\*)\s*/im, '\1')
      gsub!(/;\}/, '}')
      strip!
    end
  end
  
  # converts the source in such a way that it could be
  # delivered with javascript in the same file
  def to_javascript
    "document.write(\"<style type=\\\"text/css\\\">#{
       compact.gsub('"', '\"')
     }</style>\");"
  end
end
