require File.dirname(__FILE__)+"/spec_helper"
require File.dirname(__FILE__)+"/../lib/front_compiler_helper"

describe FrontCompilerHelper do
  include FrontCompilerHelper
  
  def front_compiler
    @c
  end
  
  before :all do 
    @c = FrontCompiler.new
  end
  
  it "should involve the js compactor" do 
    @c.should_receive(:compact_js).and_return('')
    compact_js('')
  end
  
  it "should involve the css compactor" do 
    @c.should_receive(:compact_css).and_return('')
    compact_css('')
  end
  
  it "should involve the html compactor" do 
    @c.should_receive(:compact_html).and_return('')
    compact_html('')
  end
  
  it "should involve the css compactor" do 
    @c.should_receive(:inline_css).and_return('')
    inline_css('')
  end
end
