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
                var a = hash.first.second.third.copy();
                var b = hash.firstsecond.thirdcopy();
              }
            }
          }
        }
      }
    }).should == %{
      var hash = {
        @f:  1,
        @s: 2,
        @t:  3,
        @c: {
          @f:  1,
          @s: 2,
          @t:  3,
          @c: {
            @f : 1,
            @s: 2,
            @t : 3,
            @c: {
              @f : 1,
              @s: 2,
              @t : 3,
              @c: function() {
                var a = hash.@f.@s.@t.@c();
                var a = hash.@f.@s.@t.@c();
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
            hash.a.b.c.avrora().bear.communism();
          }
        }
      }
    }).should == %{
      var hash = {
        a: 1,
        b: 2,
        c: {
          @a: {},
          @b: {},
          @c: function() {
            hash.a.b.c.@a().@b.@c();
            hash.a.b.c.@a().@b.@c();
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
          var hash = hash.first.second.third();
        }
      }
    }).should == %{
      var hash = {
        @f : 1,
        @s: 2,
        @t : function() {
          var hash = hash.f.s.t();
          var hash = hash.@f.@s.@t();
          var hash = hash.@f.@s.@t();
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
          var camel = hash.camel.cAmel().caMeL;
        }
      }
    }).should == %{
      var hash = {
        @c: 1,
        @a: 2,
        @b: function() {
          var camel = hash.@c.@a().@b;
          var camel = hash.@c.@a().@b;
        }
      }
    }
  end
  
  it "should not replace native keys if they present less then twice" do
    
    FrontCompiler::JavaScript::SelfBuilder::JS_NATIVE_KEYS.each do |key|
      compact(%{
        var something = element.#{key};
      }).should ==   %{
        var something = element.#{key};
      }
    end
  end
  
  it "should replace native keys if they present in the script more than once" do
    FrontCompiler::JavaScript::SelfBuilder::JS_NATIVE_KEYS.each do |key|
      compact(%{
        var something = element.#{key};
        var another   = something.#{key};
      }).should ==   %{
        var something = element.@#{key.slice(0,1)};
        var another   = something.@#{key.slice(0,1)};
      }
    end
  end
  
  it "should not touch the standard constructions if they are present less then twice" do
    compact(%{
      var f = function () {
        while () {
          switch () {
          }
        }
      }
    }).should == %{
      var f = function () {
        while () {
          switch () {
          }
        }
      }
    }
  end
  
  it "should shortify standard constructions when they appear in the code more than once" do
    compact(%{
      var function = function() {
        switch () {
          while () {
            do();
          }
        }
      };
      var function = function name() {
        switch () {
          while () {
            do();
          }
        }
      };
    }).should == %{
      var function = @f() {
        @s () {
          @w () {
            do();
          }
        }
      };
      var function = @f name() {
        @s () {
          @w () {
            do();
          }
        }
      };
    }
  end
  
  it "should not touch javascript commands which appears less than twice" do
    compact(%{
      return bla;
    }).should == %{
      return bla;
    }
  end
  
  it "should compress commands which are appears in the code more than once" do
    compact(%{
      return bla;
      return bla;
    }).should == %{
      @r bla;
      @r bla;
    }
  end
  
  it "should not touch javascript objects which appear less than twice in the code" do
    compact(%{
      Object.bla;
    }).should == %{
      Object.bla;
    }
  end
  
  it "should compress objects which apperas in the code more than once" do
    compact(%{
      Object.bla;
      Object.bla;
    }).should == %{
      @O.bla;
      @O.bla;
    }
  end
  
  it "should create a correct rebuild script" do
    build(%{
      var hash = {
        first : '1',
        second: "2",
        third : /3/,
        common: function() {
          hash.first.second().third;
          hash.first.second().third;
        }
      }
    }).should == "eval((function(){var s=\"\\n      var hash = {\\n        @f : '1',\\n        @s: \\\"2\\\",\\n        @t : /3/,\\n        common: function() {\\n          hash.@f.@s().@t;\\n          hash.@f.@s().@t;\\n        }\\n      }\\n    \",d={f:\"first\",s:\"second\",t:\"third\"};for(var k in d)s=s.replace(new RegExp('@'+k+'([^a-zA-Z_$])','g'),d[k]+'$1');return s})());"
  end
end