#
# This module contains the nested css handling
# it converts virtual nested css constructions to standard css constructions
# 
# Copyright (C) Nikolay V. Nemshilov aka St.
#
class FrontCompiler
  class FrontCompiler::CssSource < FrontCompiler::SourceCode
    module Nesting
      def initialize(src)
        super convert_nested_constructions(src)
      end
      
     protected
      def convert_nested_constructions(src)
        src
      end
    end
  end
end