#
# FrontCompiler, the front unit of the library
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#

class FrontCompiler
  def initialize
    @js_compactor = JSCompactor.new
  end
  
  # compacts all the files out of the list
  # and returns them as a single string
  def compact_files(list)
    list.collect do |file|
      compact_file file
    end.join("\n")
  end
  
  # compacts the given file (path or a File object)
  def compact_file(file)
    file = File.open(file, 'r') if file.is_a?(String)
    
    case file.path.split('.').last.downcase
      when 'js'   then compact_js   file.read
      when 'css'  then compact_css  file.read
      when 'html' then compact_html file.read
      else                          file.read
    end
  end
  
  # compacts a JavaScript source code
  def compact_js(source)
    @js_compactor.minimize(source)
  end
  
  # compacts a CSS source code
  def compact_css(source)
    source
  end
  
  # compacts a HTML code
  def compact_html(source)
    source
  end
end
