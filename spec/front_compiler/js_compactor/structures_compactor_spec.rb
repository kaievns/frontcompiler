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
end
