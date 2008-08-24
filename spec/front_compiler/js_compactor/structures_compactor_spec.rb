require File.dirname(__FILE__)+"/../../spec_helper"

describe FrontCompiler::JSCompactor::StructuresCompactor do
  before :all do 
    @c = FrontCompiler::JSCompactor::StructuresCompactor
  end
  
  it "should convert multi-lined if/else short constructions" do 
    @c.compact(%{
      var a = b ?
        c : d;
      var a = b
        ? c : d;
      var a = b ?
        c :
        d;
      var a = b
        ? c
        : d;
    }).should == %{
      var a = b ? c : d;
      var a = b ? c : d;
      var a = b ? c : d;
      var a = b ? c : d;
    }
  end
  
  it "should convert multi-lined assignments" do 
    @c.compact(%{ 
      var a =
        b + c;
      var a = b -
        c;
      var a = b
        % c;
    }).should == %{ 
      var a = b + c;
      var a = b - c;
      var a = b % c;
    }
  end
  
  it "should convert mutli-lined method-calls chain" do 
    @c.compact(%{
      var a = b
        .c()
        .d();
    }).should == %{
      var a = b.c().d();
    }
  end
  
  it "should convert multi-lined method calls" do 
    @c.compact(%{
      var a = b(
        c,
        d
      );
      var a = b(
        c, d
      );
    }).should == %{
      var a = b(c, d);
      var a = b(c, d);
    }
  end
  
  it "should convert multi-lined logical expressions" do 
    @c.compact(%{
      if (a
          && b ||
          c)
        var d = e
          | f &
          g;
    }).should == %{
      if (a && b || c)
        var d = e | f & g;
    }
  end
  
  it "should insert skipped semicolons" do 
    @c.compact(%{


      if (something) {
        var str = "asdf"
        var boo = something_else
      }
        else
        var foo = boo()

      if (something)
        boo()
      else { foo; boo }

      var boo = foo();
      var foo = boo
    }).should == %{


      if (something) {
        var str = "asdf";
        var boo = something_else;
      }
        else
        var foo = boo();

      if (something)
        boo();
      else { foo; boo; }

      var boo = foo();
      var foo = boo;
    }
  end
  
  it "should not touch objects and arrays definitions" do 
    @c.compact(%{
      var str = {
        a: {
          b: c,
          d: e
        },
        f: [
          g, h
        ]
      }
    }).should == %{
      var str = {
        a: {
          b: c, d: e
        }, f: [
          g, h
        ]
      };
    }
  end
  
  it "should not break try/catch/finally constructions" do 
    @c.compact(%{
      try { bla; bla
      }
      catch(e) {
        bla; bla; bla
      }
      finally { 
        bla; bla; bla
      }
    }).should == %{
      try { bla; bla;
      }
      catch(e) {
        bla; bla; bla;
      }
      finally { 
        bla; bla; bla;
      }
    }
  end
  
  it "should not touch multilined logic constructions" do 
    @c.compact(%{
      if (something) {
        bla;
        foo;
      }
      for (var k in o) {
        bla; foo;
      }
      while (something) { bla; foo; }
    }).should == %{
      if (something) {
        bla;
        foo;
      }
      for (var k in o) {
        bla; foo;
      }
      while (something) { bla; foo; }
    }
  end
  
  it "should convert simple multilined constructions" do 
    @c.compact(%{
      if (something) {
        foo;
      } else { foo }
      for (var k in o) { foo; }
      while (something()) { foo }
    }).should == %{
      if (something) 
        foo;
       else  foo; 
      for (var k in o)  foo; 
      while (something())  foo; 
    }
  end
  
  it "should keep internal multilined constructions safe" do 
    @c.compact(%{
      if (something) {
        for (var i=0; i<something.length; i++) {
          var boo = something[i];
          var foo = boo % i;
        }
      }
    }).should == %{
      if (something) 
        for (var i=0; i<something.length; i++) {
          var boo = something[i];
          var foo = boo % i;
        }
      
    }
  end
  
  it "should handle nested constructions" do 
    @c.compact(%{
      if (something) {
        for (var k in o) {
          while(something) {
            var o[k] = something;
          }
        }
      } else {
        while (something) {
          for (var k in o) {
            something = o[k];
          }
        }
      }
    }).should == %{
      if (something) 
        for (var k in o) 
          while(something) 
            var o[k] = something;
          
        
       else 
        while (something) 
          for (var k in o) 
            something = o[k];
          
        
      
    }
  end
  
  it "should keep doubleifs alive" do 
    @c.compact(%{
      if (something) {
        if (something_else) {
          bla; bla;
        }
      }
    }).should == %{
      if (something) {
        if (something_else) {
          bla; bla;
        }
      }
    }
  end
end
