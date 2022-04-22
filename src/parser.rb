# typed: ignore
require 'sorbet-runtime'
require_relative 'stick'
require_relative 'types'

return if defined? Stick::Parser

module Stick
  class SourceLocation
    extend T::Sig

    sig{ returns(String) }
    attr_reader :file

    sig{ returns(Integer) }
    attr_reader :line

    sig{ params(file: String, line: Integer).void }
    def initialize(file, line)
      @file = file
      @line = line
    end

    sig{ returns(String) }
    def to_s = "#{file}:#{line}"
  end

  class Parser
    extend T::Sig

    class ParseError < Error; end

    sig{ params(stream: String, filename: String).void }
    def initialize(stream, filename)
      @stream = stream
      @filename = filename
      @lineno = T.let(1, Integer)
    end

    sig{ returns(SourceLocation) }
    def source_location
      SourceLocation.new @filename, @lineno
    end


    sig{ returns(Group) }
    def parse
      last_source_location = begin_source_location = source_location

      acc = []
      catch :close do
        last_source_location = source_location

        while tkn = self.next
          acc.push tkn
        end

        return Group.new acc, begin_source_location
      end

      parse_error "unmatched `}`", last_source_location
    end

    private

    sig{ returns(T.nilable(String)) }
    def next_word
      @lineno += @stream.slice!(/\A\s*/)&.count("\n") || 0
      @stream.slice!(/\A(\\\n\s*|\S)+/)&.gsub(/\\\n\s*/, '')
    end

    sig{ params(message: String, source: SourceLocation).returns(T.noreturn) }
    def parse_error(message, source=source_location)
      raise ParseError, "#{source}: #{message}", caller(1)
    end

    # We need `next` as we `throw :close` to indicate group end,
    # and we don't want to have an uncaught `throw` leaking out.
    sig{ returns(T.nilable(Value)) }
    def next
      case token = next_word

      # You can stop parsing early by using `__END__`
      when '__END__', nil then nil

      # Remove comments. They can be nested.
      when ')' then parse_error 'unmatched `)`'
      when '('
        idx = 1
        start = source_location
        until idx.zero?
          case next_word
          when '(' then idx += 1
          when ')' then idx -= 1
          when nil then parse_error "unmatched `(`", start
          end
        end
        self.next

      # `:foobar` is shorthand for `"foobar"`, but without escapes.
      when /^:(?!$)/ then Scalar.new T.must $'

      # Stick only has integers for numbers: no floats
      when /^[-+]?\d+$/ then Scalar.new $&.to_i

      # Stick only has double quoted strings. Note this syntax also allows for `"foo"bar"`,
      # as strings are closed by whitespace, not `"`.
      when /^"(.*)"$/ then Scalar.new $1.gsub(/\\(?: x(\h\h) | ([^x]) )/ix) { |c|
        if $1
          $1.hex.chr
        else
          $2.tr %("'srnft0\\), %("'\s\r\n\f\t\0\\)
        end
      }


      # Parsing groups via `{` and `}`
      when '}' then throw :close
      when '{'
        body = []
        source = source_location
        catch :close do
          loop do
            body.push self.next || break
          end
        end
        Group.new body, source

      # Everything else is a variable name
      else Variable.new token
      end
    end
  end
end
