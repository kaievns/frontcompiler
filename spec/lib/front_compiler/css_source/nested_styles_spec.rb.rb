require File.dirname(__FILE__)+"/../../../spec_helper"

describe FrontCompiler::CssSource::NestedStyles do 
  def css(src)
    FrontCompiler::CssSource.new(src)
  end
  
  it "should convert nested constructions" do 
    css(%{
      div.stuff {
        border: 1px solid #EEE;

        div.name {
          font-weight: bold;

          div.id:before {
            content: '#';
          }
        }
        
        div.name, div.text {
          padding: 10pt;
          
          a.user,
          a.delete {
            background-position: left;
            background-repeat: no-repeat;
            background-image: url('user.png');
          }
          
          a.delete {
            background-image: url('delete.png');
          }
        }
      }
    }).should == %{
      div.stuff {
        border: 1px solid #EEE;
      }

        div.stuff div.name {
          font-weight: bold;
        }

          div.stuff div.name div.id:before {
            content: '#';
          }
        
        div.stuff div.name, div.stuff div.text {
          padding: 10pt;
        }
          
          div.stuff div.name a.user, div.stuff div.text a.user,
          div.stuff div.name a.delete, div.stuff div.text a.delete {
            background-position: left;
            background-repeat: no-repeat;
            background-image: url('user.png');
          }
          
          div.stuff div.name a.delete, div.stuff div.text a.delete {
            background-image: url('delete.png');
          }
    }
  end
end