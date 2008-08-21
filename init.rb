require File.dirname(__FILE__)+"/src/front_compiler"
require File.dirname(__FILE__)+"/src/front_compiler/js_compactor"
require File.dirname(__FILE__)+"/src/front_compiler/js_compactor/util"
require File.dirname(__FILE__)+"/src/front_compiler/js_compactor/names_compactor"
require File.dirname(__FILE__)+"/src/front_compiler/js_compactor/shortcuts_converter"
require File.dirname(__FILE__)+"/src/front_compiler/css_compactor"
require File.dirname(__FILE__)+"/src/front_compiler/html_compactor"

# Rails plugging in
if defined? ActionController
  require File.dirname(__FILE__)+"/lib/front_compiler_helper"
  
  ActionController::Base.class_eval {
    include FrontCompilerHelper
    helper  FrontCompilerHelper
  }
end
