require File.dirname(__FILE__)+"/../../spec_helper"

describe FrontCompiler::CssSource do
  def css(src)
    FrontCompiler::CssSource.new(src)
  end
  
  it "should remove comments" do 
    css(%{
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
    }).remove_comments!.should == %{
      
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
    css(%{
      html, body {
        font-weight: bold;


        color: red;
      }


      label {



        display: block;
      }

    }).remove_empty_lines!.should == %{
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
    css(%{ 
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
    }).remove_trailing_spaces!.should == ""\
    "html,body{cusor:pointer;color:red}div>p~label:after{"\
    "content:'           ';text-decoration:underline}"\
    "form p label{display:block}"
  end
  
  it "should apply all the minimizations to the code" do 
    css(%{ 
      /* some comment */
      div           ,
      p {         padding: 10pt; }
    }).compact!.should == %{div,p{padding:10pt}}
  end
  
  it "should convert the stylesheet into a embedded javascript code" do 
    css(%{ 
      /* some comment */
      div           ,
      p {         padding: 10pt; 
        background: url('something');
        content: "something";
     }
    }).to_javascript.should == 
      'document.write("<style type=\\"text/css\\">'+
        'div,p{padding:10pt;background:url(\'something\');content:\"something\"}'+
      '</style>");'
  end
end
