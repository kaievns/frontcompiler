require File.dirname(__FILE__)+"/../../spec_helper"

describe FrontCompiler::JSCompactor::NamesCompactor do
  before :all do 
    @c = FrontCompiler::JSCompactor::NamesCompactor
  end
  
  it "should compact local variable names" do 
    src = %{
      var something = function(bla, foo) { 
        var doo, hoo = 1;
        var moo = function(boo, foo, hoo) {
          var hoo = hoo || foo, boo = foo.something(hoo, asdf());
          foo = hoo * boo / foo;

          for (var key in foo) {
            boo = foo[key];
          }

          function moo(moo) {
            doo(hoo);

            foo_bla(hoo_moo(boo_doo))
            
            function zoo(ioo) {
              if (boo) { }
              for (var i=0; i < hoo.length; i++) hoo.bla();
            }

            var noo = function(item, i) {
              i = i || item[i]
            };
          }

          var obj = {foo: foo, boo: boo};
          var list = [foo, boo, hoo];

          return moo(foo);
        }
      }
      var toggle = function(element, className) {
        if (!(element = $(element))) return;
        return element[element.hasClassName(className) ?
          'removeClassName' : 'addClassName'](className);
      };
    }

    @c.compact(src).should == %{
      var something = function(n, p) { 
        var o, q = 1;
        var r = function(f, g, h) {
          var h = h || g, f = g.something(h, asdf());
          g = h * f / g;

          for (var j in g) {
            f = g[j];
          }

          function l(c) {
            o(h);

            foo_bla(hoo_moo(boo_doo))
            
            function e(a) {
              if (f) { }
              for (var i=0; i < h.length; i++) h.bla();
            }

            var d = function(b, a) {
              a = a || b[a]
            };
          }

          var m = {foo: g, boo: f};
          var k = [g, f, h];

          return l(g);
        }
      }
      var toggle = function(b, a) {
        if (!(b = $(b))) return;
        return b[b.hasClassName(a) ?
          'removeClassName' : 'addClassName'](a);
      };
    }
  end
  
end
