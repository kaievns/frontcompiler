#
# The HTML sources compactor
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#
class FrontCompiler::HTMLCompactor
  # applies all the compactings to the given source
  def minimize(source)
    source = remove_comments(source)
    source = remove_trailing_spaces(source)
  end
  
  # removes all the comments out of the code
  def remove_comments(source)
    source.gsub /<!--.*?-->/, ''
  end
  
  # remove all the trailing spaces out of the code
  def remove_trailing_spaces(source)
    source.gsub! /\s+/, ' '
    source.gsub! />\s+/, '>'
    source.gsub  /\s+</, '<'
  end
end
