class Parser
  def initialize(stream)
    @stream = stream
  end

  def each
    while (x=self.next)
      yield x
    end
  end

  def strip_whitespace!
    @stream.slice! /\A(?:\s+|\#.*?\n)*/
  end

  def next_number
    @stream.slice!(/\A\d+\b/)&.to_i
  end

  def next_string
    if @stream.slice! /\A(['"])((?:\\.|(?!\1).)*)\1/
      $2
    else
      @stream.slice! /\A[\w_]+/
    end
  end

  NULLARY_TOKENS = %w(add sub mul div mod pow ret print)
  NUMBER_TOKENS = %w(dup pop)
  STRING_TOKENS = %w(fn : jnz jz jmp push call)

  def next
    strip_whitespace!
    fn = @stream.slice!(/\A([\w_]+|:)\b/) or return
    strip_whitespace!

    if NULLARY_TOKENS.include? fn
      [fn, nil]
    elsif NUMBER_TOKENS.include? fn
      [fn, next_number || raise("missing argument for '#{fn}'")]
    elsif STRING_TOKENS.include? fn
      [fn, next_string || raise("missing argument for '#{fn}'")]
    else
    raise "unknown function '#{fn}'"
    end
  end
end
