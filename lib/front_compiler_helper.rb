#
# The module provides some methods which can be used
# in rails controller or something like that
#
# Generally this is just a facade for the FrontCompiler
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#

module FrontCompilerHelper
protected
  def compact_files(list)
    front_compiler.compact_files(list)
  end
  
  def compact_file(file)
    front_compiler.compact_file(file)
  end
  
  def compact_js(source)
    front_compiler.compact_js(source)
  end
  
  def compact_css(source)
    front_compiler.compact_css(source)
  end
  
  def compact_html(source)
    front_compiler.compact_html(source)
  end
  
  def inline_css(source)
    front_compiler.inline_css(source)
  end
  
  def inline_css_file(file)
    file = File.open(file) if file.is_a? String
    inline_css file.read
  end
  
private
  def front_compiler
    @front_compiler ||= FrontCompiler.new
  end
end
