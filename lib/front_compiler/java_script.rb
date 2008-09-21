#
# This class represents a java-script source code
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#
require "front_compiler/java_script/logic_compactor"
require "front_compiler/java_script/names_compactor"

class FrontCompiler::JavaScript < FrontCompiler::SourceCode
  include LogicCompactor, NamesCompactor
  
  def compact!
    string_safely do 
      remove_comments!.
        compact_logic!.
        compact_names!.
        remove_empty_lines!.
        remove_trailing_spaces!
    end
  end
  
  def remove_comments!
    string_safely do 
      gsub!(/\/\*.*?\*\//im, '')
      gsub!(/\/\/.*?($)/, '\1')
    end
  end
  
  def remove_empty_lines!
    string_safely do 
      gsub!(/\n\s*\n/m, "\n")
    end
  end
  
  def remove_trailing_spaces!
    string_safely do 
      gsub!(/\s+/im, ' ') # cutting down all spaces to the minimum
      gsub!(/\s*(=|\+|\-|<|>|\?|\|\||&&|\!|\{|\}|,|\)|\(|;|\]|\[|:|\*|\/)\s*/im, '\1')
      gsub!(/;(\})/, '\1') # removing unnecessary semicolons
      gsub!(/([^a-z\d_\$]typeof)\s+([a-z\d\$_]+)/im, '\1(\2)') # converting the typeof calls
      strip!
    end
  end
  
protected
  # extends the basic class to excape regular expressions as well
  def string_safely(&block)
    super [
      /([^\*\\\/])\/[^\*\/][^\n]*?[^\*\n\\](?!\\\/)\// # <- regexps
    ], &block
  end
end