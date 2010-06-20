require File.dirname(__FILE__)+"/../../../spec_helper"

describe FrontCompiler::JavaScript::NamesCompactor do
  def compact(src)
    FrontCompiler::JavaScript.new(src).compact_names!
  end
  
  it "should have the compact_logic method" do 
    FrontCompiler::JavaScript.new('').should respond_to(:compact_names!)
  end
  
  it "should not touch any local variables" do 
    compact(%{
      var something = funny;
    }).should == %{
      var something = funny;
    }
  end
  
  it "should handle simple cases" do 
    compact(%{
      function(something, another) {
        var more = something / another;
        another = more * something;
        something = another - more;
      }
      function (something, another) {
        var more = something / another;
      }
      function asdf(something, another) {
        var more = something / another;
      }
    }).should == %{
      function(s, a) {
        var m = s / a;
        a = m * s;
        s = a - m;
      }
      function (s, a) {
        var m = s / a;
      }
      function asdf(s, a) {
        var m = s / a;
      }
    }
  end
  
  it "should catch up local function names" do 
    compact(%{
      function() {
        function boo() {
        };
        var foo = function() {};
        var moo = function (  ) {};

        boo(foo(moo());
      }
    }).should == %{
      function() {
        function b() {
        };
        var f = function() {};
        var m = function (  ) {};

        b(f(m());
      }
    }
  end
  
  it "should catch up several vars in a line" do 
    compact(%{
      function() {
        var boo = {}, foo = [], moo = new String;
        foo.push(moo);
        boo[moo] = foo;
      }
    }).should == %{
      function() {
        var b = {}, f = [], m = new String;
        f.push(m);
        b[m] = f;
      }
    }
  end
  
  it "should keep safe the logical constructions and external variables" do 
    compact(%{
      function(something) {
        try {
          if (something) {
            for (var key in something) {
              var object = something[key];
            }
          } else if (limit) {
            for (var i=0; i < limit; i++) {
              var object = limit + i;
            }
          } else {
            while (running) {
              var object = running;
            }
          }
        } catch(MyException e) {
          handle(e);
        }
      }
    }).should == %{
      function(s) {
        try {
          if (s) {
            for (var k in s) {
              var o = s[k];
            }
          } else if (limit) {
            for (var i=0; i < limit; i++) {
              var o = limit + i;
            }
          } else {
            while (running) {
              var o = running;
            }
          }
        } catch(MyException e) {
          handle(e);
        }
      }
    }
  end
  
  it "should keep safe the objects members calls" do 
    compact(%{
      function(something) {
        var object = something.important ? 
          something.important(something.more()) : nil;
      }
    }).should == %{
      function(s) {
        var o = s.important ? 
          s.important(s.more()) : nil;
      }
    }
  end
  
  it "should resolve similar names issues" do 
    compact(%{
      function(aaron, abba, alisa) {
        var ann = aaron * abba + alisa;
      }
    }).should == %{
      function(a, b, c) {
        var d = a * b + c;
      }
    }
  end
  
  it "should handle a nested functions construction" do 
    compact(%{
      function(boo) {
        function moo() {
          function foo() {
            var moo = boo * 2;
            boo(moo);
          }
        }
        var foo = moo(boo);
      }
    }).should == %{
      function(b) {
        function c() {
          function f() {
            var m = b * 2;
            b(m);
          }
        }
        var a = c(b);
      }
    }
  end
  
  it "should not break object keys definitions" do 
    compact(%{
      function(foo, boo) {
        var moo = {foo: foo, boo  : boo};
        moo = foo ? boo : [foo, boo];
        boo = { mooboo: moo + boo }
      }
    }).should == %{
      function(f, b) {
        var m = {foo: f, boo  : b};
        m = f ? b : [f, b];
        b = { mooboo: m + b }
      }
    }
  end
  
  it "should not break similar external variables" do 
    compact(%{
      function(foo, boo) {
        var moo = foo_boo;
      }
    }).should == %{
      function(f, b) {
        var m = foo_boo;
      }
    }
  end
  
  it "should handle the case when there are two slashes but no regular expression" do
    compact(%{
      function(i) {
        var y = (cell.y/3).floor() * 3 + (i/3).floor();
      }
    }).should == %{
      function(a) {
        var y = (cell.y/3).floor() * 3 + (a/3).floor();
      }
    }
  end
  
  it "should process the multi-lined variable definitions with complex constructions in them" do
    compact(%{
      function() {
        var boo = [],
            hoo = {
              doo: [[1], [2], [3], {
                moo: {
                  zoo: [[[[[1]]]]]
                }
              }]
            },
            foo = function() {
              
            };
            
        foo(boo, hoo);
      }
    }).should == %{
      function() {
        var b = [],
            h = {
              doo: [[1], [2], [3], {
                moo: {
                  zoo: [[[[[1]]]]]
                }
              }]
            },
            f = function() {
              
            };
            
        f(b, h);
      }
    }
  end
  
  it "should process multilined variables with cross-calls" do
    compact(%{
      function() {
        var boo = "boo", hoo = {
          moo: boo,
          doo: {
            zoo: boo
          }
        }
      }
    }).should == %{
      function() {
        var b = "boo", h = {
          moo: b,
          doo: {
            zoo: b
          }
        }
      }
    }
  end
  
  it "should process several variable definitions in a mixed situation" do
    compact(%{
      function() {
        var boo = "boo", hoo = "hoo";
        
        function () {
          return boo + hoo + moo + noo();
        }
        
        var moo = "moo",
            zoo = "zoo",
            doo = "doo";
            
        function noo() {
          return boo + hoo + zoo;
        }
        
        return boo + hoo + zoo + doo;
      }
    }).should == %{
      function() {
        var b = "boo", h = "hoo";
        
        function () {
          return b + h + m + n();
        }
        
        var m = "moo",
            z = "zoo",
            d = "doo";
            
        function n() {
          return b + h + z;
        }
        
        return b + h + z + d;
      }
    }
  end
end