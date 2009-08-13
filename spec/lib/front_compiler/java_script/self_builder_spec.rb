require File.dirname(__FILE__)+"/../../../spec_helper"

describe FrontCompiler::JavaScript::SelfBuilder do
  def new_script(src)
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
      8 7 = {
        5:  1,
        0: 2,
        4:  3,
        6: {
          5:  1,
          0: 2,
          4:  3,
          6: {
            5 : 1,
            0: 2,
            4 : 3,
            6: {
              5 : 1,
              0: 2,
              4 : 3,
              6: function() {
                8 a = 7.5.0.4.6();
                8 a = 7.5.0.4.6();
                8 b = 7.50.46();
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
      var 4 = {
        a: 1,
        b: 2,
        c: {
          3: {},
          5: {},
          0: function() {
            4.a.b.c.3().5.0();
            4.a.b.c.3().5.0();
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
      6 0 = {
        5 : 1,
        3: 2,
        4 : function() {
          6 0 = 0.f.s.t();
          6 0 = 0.5.3.4();
          6 0 = 0.5.3.4();
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
      6 5 = {
        0: 1,
        4: 2,
        3: function() {
          6 0 = 5.0.4().3;
          6 0 = 5.0.4().3;
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
      3 0 = 0() {
        1 () {
          2 () {
            do();
          }
        }
      };
      3 0 = 0 name() {
        1 () {
          2 () {
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
      0 1;
      0 1;
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
      0.1;
      0.1;
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
    }).should == "eval((function(s,d){for(var i=d.length-1;i>-1;i--)if(d[i])s=s.replace(new RegExp(i,'g'),d[i]);return s})(\"\\n      var 6 = {\\n        5 : '1',\\n        0: \\\"2\\\",\\n        4 : /3/,\\n        common: function() {\\n          6.5.0().4;\\n          6.5.0().4;\\n        }\\n      }\\n    \",\"second,,,,third,first,hash\".split(\",\")));"
  end
end