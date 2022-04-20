#!ruby
require 'forwardable'

class Environment
  extend Forwardable

  attr_reader :stack, :vars

  def initialize
    @stack = []
    @stack2 = []
    @vars = {}

    self['+'] = proc { push popn(1).to_i + popi }
    self['.'] = proc { push popn(1).to_s + pops }
    self['-'] = proc { push popn(1).to_i - popi }
    self['*'] = proc { push popn(1).to_i * popi }
    self['^'] = proc { push popn(1).to_i ** popi }
    self['x'] = proc { push popn(1).to_s * popi }
    self['/'] = proc { push popn(1).to_i / popi }
    self['%'] = proc { push popn(1).to_i % popi }
    self['!'] = proc { pushb !pop.to_b }

    self['<'] = proc { pushb popn(1).to_i < popi }
    self['≤'] = proc { pushb popn(1).to_i <= popi }
    self['>'] = proc { pushb popn(1).to_i > popi }
    self['≥'] = proc { pushb popn(1).to_i >= popi }
    self['='] = proc { pushb popn(1).to_i == popi }
    self['≠'] = proc { pushb popn(1).to_i != popi }
    self['<=>'] = proc { push popn(1).to_i <=> popi }

    self['lt']  = proc { pushb popn(1).to_s < pops }
    self['le']  = proc { pushb popn(1).to_s <= pops }
    self['gt']  = proc { pushb popn(1).to_s > pops }
    self['ge']  = proc { pushb popn(1).to_s >= pops }
    self['eq']  = proc { pushb popn(1).to_s == pops }
    self['ne']  = proc { pushb popn(1).to_s != pops }
    self['cmp']  = proc { push popn(1).to_s <=> pops }

    self['warn'] = proc { warn pop.to_s }
    self['print'] = proc { print pop }
    self['println'] = proc { print "#{pop}\n" }
    self['getline'] = proc { push gets.chomp }
    self['system'] = proc { push `#{pop}` }
    self['rand'] = proc { push rand 0..0xffffffff }

    self['undef'] = proc { delete pop }
    self['def'] = proc { self[popn(1)] = pop }
    self['def?'] = proc { pushb !!self[pop] }
    self['alias'] = proc { lhs, rhs = pop 2 ; self[lhs] = rhs }
    self['abort'] = proc { abort pops }
    self['call'] = proc { pop.(self) }
    self['fetch'] = proc { push self[pops] }
    self['var'] = proc { push Token::Variable.new pops }
    self['if'] = proc {
      cond, ift, iff = pop 3
      (cond.to_b ? ift : iff).(self)
    }
    self['while'] = proc {
      cond, body = pop 2
      body.(self) while (cond.(self); pop).to_b
    }

    self['substr'] = proc { str, start, len = pop 3; push str[start, len]}
    self['dbga'] = proc { pp stack }
    self['dbgb'] = proc { pp @stack2 }
    self['quit'] = proc { exit popi }
    self['ret']  = proc { throw :ret, popi }

    self['dupn']  = proc { push stack[-popi] }
    self['popn'] = proc { popn popi - 1 }
    self['stacklen'] = proc { push @stack.length }

    self['alloc'] = proc { push Array.new popi, 0 }
    self['dalloc'] = proc { push Hash.new }
    self['get'] = proc { ary, idx = pop 2; push ary[idx.to_i] }
    self['set'] = proc { ary, idx, val = pop 3; ary[idx.to_i] = val }
    self['del'] = proc { ary, idx = pop 2; push ary.delete_at idx }
    self['len'] = proc { push pop.length }
    self['n2a'] = proc { push popi.chr }
    self['&&'] = proc { cond, block = pop 2; block.(self) if cond.to_b  }
    self['a2n'] = proc { push pops.ord }

    self['a2b'] = proc { @stack2.push pop }
    self['b2a'] = proc { push @stack2.pop }

    self['kindof'] = proc { push Hash[Integer => 'val', String => 'val',
      Token::Variable => 'var', Token::Group => 'grp', Array => 'ary'][pop.class] }
    self['wrapn'] = proc { push Token::Group.new pop popi }
    self['blockn'] = proc { p pop.is_a? Token::Group; exit ; push Token::Group.new pop popi }
    self['unwrap'] = proc { @stack.concat pop.data }

    # stuff that could be written natively
    self['dup'] = proc { push @stack.last }
    self['dup2'] = proc { push @stack[-2] }
    self['dup3'] = proc { push @stack[-3] }
    self['pop'] = proc { pop }
    self['pop2'] = proc { popn 1 }
    self['pop3'] = proc { popn 2 }
    self['swap'] = proc { @stack.concat pop(2).reverse }
    self['rot']  = proc { @stack.concat pop(3).rotate }
    self['1+']  = proc { push popi + 1 }
    self['1-']  = proc { push popi - 1 }
    self['rev'] = proc { push @stack.pop.reverse }
    self['ifl'] = proc {
      cond, ift, iff = pop 3
      push cond.to_b ? ift : iff
    }

    self['read-file'] = proc { push open(pops, &:read) }
    self['split'] = proc { str, split = pop 2; push str.to_s.split split.to_s }
    self['join'] = proc { ary, glue = pop 2; push ary.join(glue) }
    self['apush\''] = proc { p _1; exit }

    self['__bad_bind'] = proc {
      body = pop
      old = {}
      while (name = pop) != '$'
        old[name] = self[name]
      end

        p [body, old]
      begin
        old.each do |k, _|
          self[k] = Token::Group.new([pop])
        end

        body.(self)
      ensure
        old.each do |k, v|
          if v.nil?
            delete k
          else
            self[k] = v
          end
        end
      end
    }
    end

# \fizzbuzz {
#   0
#   { dup2 dup2 < }
#   {
#     1 +
#     dup
#     fizzbuzz_inner
#     "\n" cat
#     print
#   }
#   while
# } def
#   end

  def_delegators :@vars, :[], :[]=, :delete
  def_delegators :@stack, :push, :pop

  def popi(...) = pop(...).to_i
  def pops(...) = pop(...).to_s

  def pushb(b) = push(b ? 1 : 0)

  def push(n)
    raise unless n
    @stack << n
  end

  def popn(n) = @stack.delete_at(~n)
  alias << push
  def >>(x) = pop(x).rotate(-1)
end

class String
  def run(env) = env << self
  def call(_env) = self
  def to_b = !empty? && self != '0'
end


class Array
  def run(env) = env << self
end

class Proc
  def run(env) = env << self
end

class Integer
  def run(env) = env << self
  def call(_env) = self
  def to_b = nonzero?
end

class Token
  attr_reader :data
  def initialize data
    @data = data
  end

  def call(_env) = @data

  class Group < Token
    def inspect = "Group(#{@data.inspect[1..-2]})"

    def run(env) = env.push(self)
    def call(env)
      amnt = catch :ret do
        @data.each { _1.run env }
        return
      end
      throw :ret, amnt - 1 if amnt.positive?
    end
  end

  class Variable < Token
    def inspect = ":#@data"
    def run env
      x = env[@data] or raise "unknown variable '#@data'"
      x.(env)
    end
  end
end

class Parser
  def initialize(src)
    @src = src.split
  end

  def grp
    @src.unshift '{'
    @src << '}'
    self.next
  end

  def next
    case tkn=@src.shift
    when '__END__' then throw :close
    when '((include'
      @src.shift =~ /^'(.*)'\)\)$/ or raise "syntax: ((include '<filename>'))"
      @src = open($1, &:read).split + @src
      self.next
    when ?(
      idx = 1
      until idx.zero?
        n = @src.shift
        idx += n.count ?(
        idx -= n.count ?)
        fail "too many `)`s encountered in a row" if idx.negative?
      end

      self.next
    when /^:/ then $'
    when /^`/ then @src.unshift 'fetch' ; $'
    when /^[-+]?\d+$/ then tkn.to_i
    when /^(?:"(.*)"|'(.*)')$/ then $+.gsub(/\\(?:x\h\h|[^x])/) { |c|
      if c[1] == ?x
        c[2..].hex.chr
      else
        c[1].tr 'srnft\'\\"0', "\s\r\n\f\t\'\\\"\0"
      end
    }.tr('•', ' ')
    when ?{
      grp = []
      catch :close do
        loop { grp.push self.next }
      end
      Token::Group.new grp
    when ?}     then throw :close
    when String then Token::Variable.new tkn
    else raise "unknown token start #{tkn.inspect}"
    end
  end
end

e = Environment.new
# Parser.new(open(File.join(__dir__, 'prelude.sk'), &:read)).grp.(e)
# Parser.new(open(File.join(__dir__, 'list.sk'), &:read)).grp.(e)
$*.unshift '/dev/stdin' if $*.empty?
Parser.new(open($*.shift, &:read)).grp.(e) #rescue puts "error: #$!"
# Parser.new(<<EOS).grp.(e)
# 1 2 - println
# EOS
