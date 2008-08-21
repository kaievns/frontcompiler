require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'front_compiler'))

ActionController::Base.class_eval {
  include FrontCompilerHelper
  helper  FrontCompilerHelper
}

