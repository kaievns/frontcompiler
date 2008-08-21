require File.dirname(__FILE__)+"/../spec_helper"

describe FrontCompiler::CSSCompactor do
  before :all do 
    @c = FrontCompiler::CSSCompactor.new
  end
  
  it "should remove comments" do 
    @c.remove_comments(%{
      /* some styleshit here */
      html, body { 
        font-size: 9pt;
      }
      /* some more styleshit */
      p {
        padding: 10pt;
        background: url("/*/*/image.png");
      }

      a:after {
        content: '/* */';
      }
    }).should == %{
      
      html, body { 
        font-size: 9pt;
      }
      
      p {
        padding: 10pt;
        background: url("/*/*/image.png");
      }

      a:after {
        content: '/* */';
      }
    }
  end
  
  it "should remove all the empty lines out of the code" do 
    @c.remove_empty_lines(%{
      html, body {
        font-weight: bold;


        color: red;
      }


      label {



        display: block;
      }

    }).should == %{
      html, body {
        font-weight: bold;
        color: red;
      }
      label {
        display: block;
      }
    }
  end
  
  it "should remove all the trailing spaces out of the code" do 
    @c.remove_trailing_spaces(%{ 
      html, body { 
        cusor :    pointer;
        color: red;
      }


      div     > p  ~  label:after { 
            content: '           ';
        text-decoration: underline;
      }

      form p label { 
        display: block;
      }
    }).should == %{html,body{cusor:pointer;color:red;}div>p~label:after{content:'           ';text-decoration:underline;}form p label{display:block;}}
  end
end
