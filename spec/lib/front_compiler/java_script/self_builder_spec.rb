require File.dirname(__FILE__)+"/../../../spec_helper"

describe FrontCompiler::JavaScript::SelfBuilder do
  def compact(src)
    FrontCompiler::JavaScript.new(src).instance_eval do
      compact_hashes_in(self).first
    end
  end
  
  def build(src)
    FrontCompiler::JavaScript.new(src).instance_eval do
      process_hashes_in self
    end
  end

  it "should compact the hash names in a simple case like that" do
    compact(%{
      var hash = {
        first:  1,
        second: 2,
        third:  3,
        copy: {
          first:  1,
          second: 2,
          third:  3,
          copy: {
            first : 1,
            second: 2,
            third : 3,
            copy: {
              first : 1,
              second: 2,
              third : 3,
              copy: function() {
                var a = hash.first.second.third.copy();
                var b = hash.firstsecond.thirdcopy();
              }
            }
          }
        }
      }
    }).should == %{
      var hash = {
        f:  1,
        s: 2,
        t:  3,
        c: {
          f:  1,
          s: 2,
          t:  3,
          c: {
            f : 1,
            s: 2,
            t : 3,
            c: {
              f : 1,
              s: 2,
              t : 3,
              c: function() {
                var a = hash.f.s.t.c();
                var b = hash.firstsecond.thirdcopy();
              }
            }
          }
        }
      }
    }
  end
  
  it "should watch keys intersections when rename keys" do
    compact(%{
      var hash = {
        a: 1,
        b: 2,
        c: {
          avrora: {},
          bear: {},
          communism: function() {
            hash.a.b.c.avrora().bear.communism();
          }
        }
      }
    }).should == %{
      var hash = {
        a: 1,
        b: 2,
        c: {
          d: {},
          e: {},
          f: function() {
            hash.a.b.c.d().e.f();
          }
        }
      }
    }
  end
  
  it "should watch other methods intersections when rename keys" do
    compact(%{
      var hash = {
        first : 1,
        second: 2,
        third : function() {
          var hash = hash.f.s.t();
          var hash = hash.first.second.third();
        }
      }
    }).should == %{
      var hash = {
        a : 1,
        b: 2,
        c : function() {
          var hash = hash.f.s.t();
          var hash = hash.a.b.c();
        }
      }
    }
  end
  
  it "should be casesensitive" do
    compact(%{
      var hash = {
        camel: 1,
        cAmel: 2,
        caMeL: function() {
          var camel = hash.camel.cAmel().caMeL;
        }
      }
    }).should == %{
      var hash = {
        c: 1,
        a: 2,
        b: function() {
          var camel = hash.c.a().b;
        }
      }
    }
  end
  
  it "should create a correct rebuild script" do
    build(%{
      var hash = {
        first : 1,
        second: 2,
        third : 3,
        common: function() {
          hash.first.second().third
        }
      }
    }).should == %[eval((function(){var s=function(){
      var hash = {
        f : 1,
        s: 2,
        t : 3,
        c: function() {
          hash.f.s().t
        }
      }
    }.toString().replace(/^\\s*function\\s*\\(\\)\\s*{/,'').replace(/\\}\\s*;?\\s*$/,'');var d={c:"common",f:"first",s:"second",t:"third"};for(var k in d)s=s.replace(new RegExp('((\\\\{|,)\\\\s*)'+k+'(\\\\s*:)','g'),'$1'+d[k]+'$3').replace(new RegExp('(\\\\.)'+k+'([^a-zA-Z0-9_\\\\$\\\\-])','g'),'$1'+d[k]+'$2');return s;}()));]
  end
end