class StickError < RuntimeError; end

class Object
  def run = $env.push(self)
end

class Variable
  class UnknownVariable < StickError; end

  def initialize(name) 
    @name = name
  end

  alias call itself
  def inspect = ":#@name"

  def run
    $env.fetch(@name) { raise UnknownVariable, "unknown variable '#@name'" }.call
  end
end

class TokenGroup
  def initialize(tokens) = @tokens = tokens
  def inspect = "Group(#{@tokens.inspect[1..-2]})"
  def call = @tokens.each(&:run)
end

class Parser
  class ParseError < StickError; end

  def initialize(src)
    @src = src.split
  end

  def next
    case (token=@src.shift)
    when '__EOF__', nil then nil

    # Comments
    when ')' then raise ParseError, "unmatched `)`"
    when '('
      idx = 1
      until idx.zero?
        case @src.shift
        when '(' then idx += 1
        when ')' then idx -= 1
        when nil then raise ParseError, "unmatched `(`"
        end
      end
      self.next

    # Literals
    when /^[-+]?\d+$/ then token.to_i
    when /^:/ then $' # `:` is shorthand for `"..."`, but `...` taken literally
    when /^"(.*)"$/ then $1.gsub /\\(?:x\h\h|[^x])/ do |c|
      if c[1] == ?x
        c[2..].hex.chr
      else
        c[1].tr 'srnft"\'\\', " \r\n\f\t\"'\\"
      end
    end

    # Groups
    when '}' then throw :close
    when '{'
      group = []
      catch :close do
        loop { group.push self.next }
      end
      TokenGroup.new grp

    # Otherwise, it's a variable
    else Variable.new tkn
    end
  end
end
