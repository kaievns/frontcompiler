require File.dirname(__FILE__)+"/../../spec_helper"

describe FrontCompiler::SourceCode do 
  before :all do 
    @src = FrontCompiler::SourceCode.new("bla")
  end
  it "should extend the String class" do 
    @src.should == "bla"
  end
  
  it do 
    @src.should respond_to(:compact)
  end
  
  it do 
    @src.should respond_to(:remove_comments)
  end
  
  it do 
    @src.should respond_to(:remove_empty_lines)
  end
  
  it do 
    @src.should respond_to(:remove_trailing_spaces)
  end
end