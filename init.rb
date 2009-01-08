require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'front_compiler'))

if defined? ActionController
  ActionController::Base.class_eval {
    include FrontCompilerHelper
    helper  FrontCompilerHelper
  }
end

# Rails 2.2
if defined? ActionView::Helpers::AssetTagHelper::AssetCollection
  ActionView::Helpers::AssetTagHelper::JavaScriptSources.class_eval do
    alias :original_joined_contents :joined_contents
    def joined_contents
      FrontCompiler.new.compact_js(original_joined_contents)
    end
  end
  ActionView::Helpers::AssetTagHelper::StylesheetSources.class_eval do
    alias :original_joined_contents :joined_contents
    def joined_contents
      FrontCompiler.new.compact_css(original_joined_contents)
    end
  end
end

