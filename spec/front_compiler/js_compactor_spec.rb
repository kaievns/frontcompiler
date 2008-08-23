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
  
  it "should convert the one-line constructions" do
    @c.convert_one_line_constructions(%{
      var str1 = "if (smth) smth;";
      
      for (var i=0; i < smth(str.substr(1,2)); i++)
        while (something(asdf))
          if (anotherthing(i)) return false

      if (something)
        bla();
      else boo();

      if (another)
        while (something()) { for (asdfasf;asdfa;asd) {  asdf; }}
      else
        while (something()) { return true; }

      if (something) something = function(bla, bla) {
        bla_bla(bla);
      };

      if (params = Object.toQueryString(params)) {
        if (this.method == 'get')
          this.url += (this.url.include('?') ? '&' : '?') + params;
        else if (/Konqueror|Safari|KHTML/.test(navigator.userAgent))
          params += '&_=';
      }

      if (this.transport.overrideMimeType &&
          (navigator.userAgent.match(/Gecko\\/(\\d{4})/) || [0,2005])[1] < 2005)
            headers['Connection'] = 'close';
    }).should == %{
      var str1 = "if (smth) smth;";
      
      for (var i=0; i < smth(str.substr(1,2)); i++){
        while (something(asdf)){
          if (anotherthing(i)){ return false}}}

      if (something){
        bla();}
      else {boo();}

      if (another){
        while (something()) { for (asdfasf;asdfa;asd) {  asdf; }}}
      else
        {while (something()) { return true; }}

      if (something){ something = function(bla, bla) {
        bla_bla(bla);
      };}

      if (params = Object.toQueryString(params)) {
        if (this.method == 'get'){
          this.url += (this.url.include('?') ? '&' : '?') + params;}
        else if (/Konqueror|Safari|KHTML/.test(navigator.userAgent)){
          params += '&_=';}
      }

      if (this.transport.overrideMimeType &&
          (navigator.userAgent.match(/Gecko\\/(\\d{4})/) || [0,2005])[1] < 2005){
            headers['Connection'] = 'close';}
    }
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
