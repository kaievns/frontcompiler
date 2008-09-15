require File.dirname(__FILE__)+"/../spec_helper"

describe FrontCompiler::JavaScript do 
  def js(src)
    FrontCompiler::JavaScript.new(src)
  end
  
  it "should remove comments" do 
    js(%{
      /**
       * bla bla bla
       */
      var bla = // bla bla bla
        "bla // bla /* bla */";
    }).remove_comments.should == %{
      
      var bla = 
        "bla // bla /* bla */";
    }
  end
  
  it "should remove empty lines" do 
    js(%{
      
      var str1 = "asdfsdf \\n\\n\\n asd";
      var str2 = 'asdfasdf';



    }).remove_empty_lines.should == %{
      var str1 = "asdfsdf \\n\\n\\n asd";
      var str2 = 'asdfasdf';
    }
  end
  
  it "should remove trailing spaces" do 
    js(%{
      for ( var bla = "asdf + asdf"; bla.match(/sdfsdf [ ]/ ); [ sdfsdf % sdf ]) {
        bla(
          bla(bla, bla),
          bla_bla  / bla_bla_bla * sdfsd - asfasdf
        );
      }
    }).remove_trailing_spaces.should == "" \
      "for(var bla=\"asdf + asdf\";bla.match(/sdfsdf [ ]/);[sdfsdf % sdf]){" \
        "bla(bla(bla,bla),bla_bla/bla_bla_bla*sdfsd-asfasdf)}"
  end
  
  it "should escape/restore strings and regexps properly" do 
    js(%{
      var str = "asdf \\\\ \\n /* asdf */";
      var str = /\\D/;
      var str = '\\D';
    }).remove_comments.should == %{
      var str = "asdf \\\\ \\n /* asdf */";
      var str = /\\D/;
      var str = '\\D';
    }
  end
end