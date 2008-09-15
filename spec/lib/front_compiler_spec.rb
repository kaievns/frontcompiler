require File.dirname(__FILE__)+"/../spec_helper"

describe FrontCompiler do 
  before :each do 
    @js = FrontCompiler::JavaScript.new ''
    @css = FrontCompiler::CSSCompactor.new
    @html = FrontCompiler::HTMLCompactor.new
    
    FrontCompiler::CSSCompactor.should_receive(:new).and_return(@css)
    FrontCompiler::HTMLCompactor.should_receive(:new).and_return(@html)
    
    @c = FrontCompiler.new
  end
  
  it "should involve the js compactor" do 
    FrontCompiler::JavaScript.should_receive(:new).and_return(@js)
    @js.should_receive(:compact).and_return('')
    @c.compact_js('')
  end
  
  it "should involve the css compactor" do 
    @css.should_receive(:minimize).and_return('')
    @c.compact_css('')
  end
  
  it "should involve the html compactor" do 
    @html.should_receive(:minimize).and_return('')
    @c.compact_html('')
  end
  
  it "should involve the css compactor" do 
    @css.should_receive(:to_javascript).and_return('')
    @c.inline_css('')
  end
end
