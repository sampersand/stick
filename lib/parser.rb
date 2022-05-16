module Stick
  class SourceLocation
    attr_reader :filename, :lineno

    def initialize(filename, lineno)
      @filename = filename
      @lineno = lineno
    end

    def to_s = "#@filename:#@lineno"

    def error(message)
      raise ParseError, "#{self}: #{message}", caller(1)
    end
  end

  class Parser
    class ParseError < Error; end

    def initialize(stream, filename)
      @stream = stream
      @filename = filename
      @lineno = 1
    end

    def location
      SourceLocation.new @filename, @lineno
    end

    def parse
      catch :close do
        acc = []
        start = location

        while tkn = next_token
          acc.push tkn
        end

        return Group.new acc, start
      end.error 'unmatched `}`'
    end

    private

    def next_word
      @lineno += @stream.slice!(/\A\s*/)&.count("\n") || 0
      @stream.slice!(/\A\S+/)
    end

    # We need `next` as we `throw :close` to indicate group end,
    # and we don't want to have an uncaught `throw` leaking out.
    def next_token
      start = location
      case token = next_word

      # You can stop parsing early by using `__END__`
      when nil, '__END__' then nil

      # Remove comments. They can be nested.
      when ')' then start.error 'unmatched `)`'
      when '('
        idx = 1
        until idx.zero?
          case next_word
          when '(' then idx += 1
          when ')' then idx -= 1
          when nil then start.error 'unmatched `(`'
          end
        end
        next_token

      # `:foobar` is shorthand for `"foobar"`, but without escapes.
      when /^:(?!$)/ then $'

      # Stick only has integers for numbers: no floats
      when /^[-+]?\d+$/ then $&.to_i

      # Stick only has double quoted strings. Note this syntax also allows for `"foo"bar"`,
      # as strings are closed by whitespace, not `"`.
      when /^"(.*)"$/ then $1.gsub(/\\(?: x(\h\h) | ([^x]) )/ix) { |c|
        $1 ? $1.hex.chr : $2.tr("\"\'srnft0\\", "\"\'\s\r\n\f\t\0\\")
      }

      # Parsing groups via `{` and `}`
      when '}' then throw :close, start
      when '{'
        body = []

        catch :close do
          while token = next_token
            body.push token
          end

          # if we reached an `}`, it'd be caught by `catch`, so this is only run if we reached eof.
          start.error 'unmatched `{`'
        end

        Group.new body, start

      # Everything else is a variable name
      else
        Variable.new token
      end
    end
  end
end
