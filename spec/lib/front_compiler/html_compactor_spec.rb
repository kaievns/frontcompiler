require File.dirname(__FILE__)+"/../../spec_helper"

describe FrontCompiler::HTMLCompactor do
  before :all do 
    @c = FrontCompiler::HTMLCompactor.new
  end
  
  it "should remove all the comments out of the code" do 
    @c.remove_comments(%{ 
      <ul><!-- main menu -->
        <li><!-- main label -->
          Main</li>
      </ul>
    }).should == %{ 
      <ul>
        <li>
          Main</li>
      </ul>
    }
  end
  
  it "should remove all the trailing spaces out of the code" do 
    @c.remove_trailing_spaces(%{ 
      <ul     class="bla">
         <li>
           <a href=""       id="main">     Home </a>
         </li>
      </ul>
    }).should == %{<ul class="bla"><li><a href="" id="main">Home</a></li></ul>}
  end
  
  it "should apply all the compactings" do 
    @c.minimize(%{ <!-- some comment -->
      <ul     class="bla">
         <li>  <!-- some another comment -->
           <a href=""       id="main">     Home </a>
         </li>
      </ul>
    }).should == %{<ul class="bla"><li><a href="" id="main">Home</a></li></ul>}
  end
end
