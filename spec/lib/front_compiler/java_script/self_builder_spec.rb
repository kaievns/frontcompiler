require File.dirname(__FILE__)+"/../../../spec_helper"

describe FrontCompiler::JavaScript::SelfBuilder do
  def compact(src)
#    FrontCompiler::JavaScript::SelfBuilder::MINIMUM_NUMBER_OF_APPEARANCES = 2
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
        @fi:  1,
        @se: 2,
        @th:  3,
        @co: {
          @fi:  1,
          @se: 2,
          @th:  3,
          @co: {
            @fi : 1,
            @se: 2,
            @th : 3,
            @co: {
              @fi : 1,
              @se: 2,
              @th : 3,
              @co: function() {
                var a = hash.@fi.@se.@th.@co();
                var a = hash.@fi.@se.@th.@co();
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
          @av: {},
          @be: {},
          @co: function() {
            hash.a.b.c.@av().@be.@co();
            hash.a.b.c.@av().@be.@co();
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
        @fi : 1,
        @se: 2,
        @th : function() {
          var hash = hash.f.s.t();
          var hash = hash.@fi.@se.@th();
          var hash = hash.@fi.@se.@th();
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
        @ca: 1,
        @cA: 2,
        @aa: function() {
          var camel = hash.@ca.@cA().@aa;
          var camel = hash.@ca.@cA().@aa;
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
        var something = element.@#{key.slice(0,2)};
        var another   = something.@#{key.slice(0,2)};
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
      var function = @fu() {
        @sw () {
          @wh () {
            do();
          }
        }
      };
      var function = @fu name() {
        @sw () {
          @wh () {
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
      @re bla;
      @re bla;
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
      @Ob.bla;
      @Ob.bla;
    }
  end
  
  it "should create a correct rebuild script" do
    build(%{
      var hash = {
        first : '1',
        second: "2",
        third : /3/,
        common: function() {
          hash.first.second().third
        }
      }
    }).should == "eval((function(){var s=\"\\n      var hash = {\\n        first : '1',\\n        second: \\\"2\\\",\\n        third : /3/,\\n        common: function() {\\n          hash.first.second().third\\n        }\\n      }\\n    \",d={};for(var k in d)s=s.replace(new RegExp('@'+k,'g'),d[k]);return s})());"
  end
end