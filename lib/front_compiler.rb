#
# FrontCompiler, the front unit of the library
#
# Copyright (C) Nikolay V. Nemshilov aka St.
#
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__))).uniq!

class FrontCompiler
  VERSION = "0.1"
  
  def initialize
    @html_compactor = HTMLCompactor.new
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
    JavaScript.new(source).compact
  end
  
  # compacts a CSS source code
  def compact_css(source)
    CssSource.new(source).compact
  end
  
  # compacts a HTML code
  def compact_html(source)
    @html_compactor.minimize(source)
  end
  
  # inlines the css-sourcecode in a javascript code
  def inline_css(source)
    CssSource.new(source).to_javascript
  end
end

require "front_compiler/source_code"
require "front_compiler/java_script"
require "front_compiler/css_source"
require "front_compiler/html_compactor"
