module FrontCompiler::JSCompactor::Util
  # searches for a block in the stack
  # means a block of code wich includes possible nested constructions
  #
  # s = "(something(asdf())) asdfasdf"
  #
  # will return
  #
  # "(something(asdf()))"
  # 
  BLOCK_CHUNKS = { "(" => ")", "{" => "}", "[" => "]" } unless defined? BLOCK_CHUNKS
  
  def find_block(stack, left="(")
    right = BLOCK_CHUNKS[left]
    block = stack[/\A\s*#{Regexp.escape(left)}/im] || ''    
    stack = stack[block.size, stack.size]
    
    count = 0
    (0...stack.size).each do |i|
      char = stack[i,1]
      
      block << char
      
      if char == right and count == 0
        break
      else
        count += 1 if char == left
        count -= 1 if char == right
      end
    end
    
    block
  end
end
