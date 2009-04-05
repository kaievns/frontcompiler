require File.dirname(__FILE__)+"/../../../spec_helper"

describe FrontCompiler::JavaScript::SelfBuilder do
  def new_script(src)
    FrontCompiler::JavaScript.minum_number_of_entry_appearances = 2
    FrontCompiler::JavaScript.new(src)
  end
  
  def compact(src)
    new_script(src).instance_eval do
      compact_hashes_in(self).first
    end
  end
  
  def build(src)
    new_script(src).instance_eval do
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
      var @h = {
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
                var a = @h.@f.@s.@t.@c();
                var a = @h.@f.@s.@t.@c();
                var b = @h.firstsecond.thirdcopy();
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
      var @h = {
        a: 1,
        b: 2,
        c: {
          @a: {},
          @b: {},
          @c: function() {
            @h.a.b.c.@a().@b.@c();
            @h.a.b.c.@a().@b.@c();
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
      var @h = {
        @f : 1,
        @s: 2,
        @t : function() {
          var @h = @h.f.s.t();
          var @h = @h.@f.@s.@t();
          var @h = @h.@f.@s.@t();
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
      var @h = {
        @c: 1,
        @b: 2,
        @a: function() {
          var @c = @h.@c.@b().@a;
          var @c = @h.@c.@b().@a;
        }
      }
    }
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
      var @f = @f() {
        @s () {
          @w () {
            do();
          }
        }
      };
      var @f = @f name() {
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
    }).should == "eval((function(){var s=\"\\n      var @h = {\\n        @f : '1',\\n        @s: \\\"2\\\",\\n        @t : /3/,\\n        common: function() {\\n          @h.@f.@s().@t;\\n          @h.@f.@s().@t;\\n        }\\n      }\\n    \",d=\"f:first,h:hash,s:second,t:third\".split(\",\");for(var i=0;i<d.length;i++){p=d[i].split(\":\");s=s.replace(new RegExp('@'+p[0]+'([^a-zA-Z0-9_$])','g'),p[1]+'$1');}return s})());"
  end
end