require File.dirname(__FILE__)+"/../spec_helper"

describe FrontCompiler::JSCompactor do
  before :all do 
    @c = FrontCompiler::JSCompactor.new
  end
  
  it "should remove all the comments" do 
    @c.remove_comments(%{
      /**
       * some comment
       */
      var /* bla */ smth = 1; // bla
      // asdfasdf
      var str1 = '/* */';
      var str2 = "/* */";
      var str3 = "//";
    }).should == %{
      
      var  smth = 1; 
      
      var str1 = '/* */';
      var str2 = "/* */";
      var str3 = "//";
    }
  end
  
  it "should remove all the empty lines" do 
    @c.remove_empty_lines(%{
      
      var str1 = "asdfsdf \\n\\n\\n asd";
      var str2 = 'asdfasdf';



    }).should == %{
      var str1 = "asdfsdf \\n\\n\\n asd";
      var str2 = 'asdfasdf';
    }
  end
  
  it "should remove trailing spaces" do 
    @c.remove_trailing_spaces(%{
      var f = function(asdf, asdf) { 
        if (smth(asdf, asdf)) {
          for (var i = 0; i < asdf.length; i++) { 
            while (asdf && asdf) {
              do_something(weird);
              var str1 = "asdf      sdf(    ) { asdfasdf }";
              var str2 = "sdfsdfsdf if (asdf) { asdf }";
              var type = typeof str2;
            }
          }
        }
      };
    }).should == %{ var f=function(asdf,asdf){if(smth(asdf,asdf)){for(var i=0;i<asdf.length;i++){while(asdf&&asdf){do_something(weird);var str1="asdf      sdf(    ) { asdfasdf }";var str2="sdfsdfsdf if (asdf) { asdf }";var type=typeof(str2)}}}};}
  end
  
  it "should compact local variable names" do 
    src = %{
      var something = function(bla, foo) { 
        var str = "function(asdf, boo) { asdf(); boo; }"
        var doo, hoo = 1;
        var hoo = hoo || foo, boo = foo.something(hoo, asdf());
        foo = hoo * boo / foo;
      }
    }

    @c.compact_local_names(src).should == %{
      var something = function(a, d) { 
        var f = "function(asdf, boo) { asdf(); boo; }"
        var c, e = 1;
        var e = e || d, b = d.something(e, asdf());
        d = e * b / d;
      }
    }
  end
  
  it "should apply all the compactions in the minimize method" do 
    src = %{
      /**
       * some comment
       */
      var something = function(bla, foo) { 
        var str = "function(asdf, boo) { asdf(); boo; }";
        var doo, hoo = 1;
        var moo = function(boo, foo, hoo) {
          var hoo = hoo || foo, boo = foo.something(hoo, asdf());
          foo = hoo * boo / foo;

          function moo(moo) {
            doo(hoo);

            foo_bla(hoo_moo(boo_doo));
            
            function zoo(ioo) {
              if (boo) { }
              for (var i=0; i < hoo.length; i++) hoo.bla();
            }
          }

          return moo(foo);
        }
      }
    }
    
    @c.minimize(src).should == %{var something=function(h,k){var n="function(asdf, boo) { asdf(); boo; }";var j,l=1;var m=function(d,e,f){var f=f||e,d=e.something(f,asdf());e=f*d/e;function g(b){j(f);foo_bla(hoo_moo(boo_doo));function c(a){if(d){}for(var i=0;i<f.length;i++)f.bla()}}return g(e)}}}
  end
  
  it "should escape strings and regexps properly" do 
    @c.remove_comments(%{
      var str = "asdf \\\\ \\n /* asdf */";
      var str = /\\D/;
      var str = '\\D';
    }).should == %{
      var str = "asdf \\\\ \\n /* asdf */";
      var str = /\\D/;
      var str = '\\D';
    }
  end
end
