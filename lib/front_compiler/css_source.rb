#
# The CSS sources compactor
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#
class FrontCompiler::CssSource < FrontCompiler::SourceCode
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
  
protected
  # escapes all the strings defined in the source
  # and get everything back after processing
  # to keep the strings safe
  def string_safely
    outtakes = []
    
    gsub!(/('|").*?[^\\](\1)/) do |match|
      replacement = "sfTEEg$%#{outtakes.length}$%riPlOcImEnt"
      outtakes << { 
        :replacement => replacement, 
        :original    => match.to_s
      }
      
      replacement
    end
    
    # running the handler
    yield
    
    # bgingin the strings back
    outtakes.reverse.each do |s|
      gsub! s[:replacement], s[:original].gsub('\\','\\\\\\\\')
    end
    
    self
  end
end
