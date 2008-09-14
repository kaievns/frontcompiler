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
  def compact
    remove_comments.
      remove_empty_lines.
      remove_trailing_spaces
  end
  
  # removes any comments
  def remove_comments
    self
  end
  
  # removes empty lines
  def remove_empty_lines
    self
  end
  
  # removes all the trailing spaces
  def remove_trailing_spaces
    self
  end
end