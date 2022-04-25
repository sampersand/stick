# typed: true
require 'sorbet-runtime'

module Stick
  class Environment
    extend T::Sig

    class UnknownVariable < RunError
      extend T::Sig

      sig{ returns(String) }
      attr_reader :name

      sig{ params(name: String, callstack: T::Array[SourceLocation]).void }
      def initialize(name, callstack)
        super "undefined variable #{name.inspect}", callstack
        @name = name
      end
    end

    DEFAULT_VARIABLES = T.let({}, T::Hash[String, NativeFunction])

    sig{ returns(T::Array[Value]) }
    attr_reader :stack1

    sig{ returns(T::Array[Value]) }
    attr_reader :stack2

    sig{ returns(T::Hash[String, Value]) }
    attr_reader :variables

    sig{ void }
    def initialize
      @stack1 = T.let [], T::Array[Value]
      @stack2 = T.let [], T::Array[Value]
      @variables = T.let DEFAULT_VARIABLES.dup, T::Hash[String, Value]

      @callstack = T.let [], T::Array[SourceLocation]
    end

    sig{ params(frame: SourceLocation, block: T.proc.void).void }
    def with_stackframe(frame, &block)
      @callstack.push frame
      block.call
    ensure
      @callstack.pop
    end

    sig{ params(value: Value).void }
    def push(value) = @stack1.push(value)

    sig{ params(a: T.untyped).returns(T::Array[Value]) }
    def pop(*a) = T.unsafe(@stack1).pop(*a)

    sig{ params(n: Integer).returns(Value) }
    def popn(n)
      @stack1.delete_at(~n) or raise RunError, "pop out of bounds, max #{@stack1.length}, given #{n}"
    end

    sig{ params(name: String).returns(T.nilable(Value)) }
    def delete_variable(name)
      @variables.delete name.to_s
    end

    sig{ params(name: String, value: Value).void }
    def define_variable(name, value)
      @variables[name.to_s] = value
    end

    sig{ params(name: String).returns(T::Boolean) }
    def variable_defined?(name)
      @variables.include? name.to_s
    end

    sig{ returns(T::Array[SourceLocation]) }
    def callstack = @callstack.clone

    sig{ params(name: String).returns(Value) }
    def fetch_variable(name)
      @variables.fetch (name=name.to_s) do
        raise UnknownVariable.new name, callstack
      end
    end

    sig{
      params(
        name: String,
        kw: T::Boolean,
        block: T.untyped # proc.params(arg0: Value, arg1: Value, arg2: Value).returns(T.untyped)
      ).void
    }
    def self.define(name, **kw, &block)
      DEFAULT_VARIABLES[name] = T.unsafe(Stick::NativeFunction).new(name, **kw, &block)
    end

    ## BOOLEAN METHOD
    define '!' do
      raise RunError, "#{_1.class} is not a scalar" unless _1.is_a? Scalar
      !_1.truthy?
    end

    ## NUMBER METHODS
    define('~') { -_1.to_i }
    define('+') { _1.to_i + _2.to_i }
    define('-') { _1.to_i - _2.to_i }
    define('*') { _1.to_i * _2.to_i }
    define('/') { _1.to_i / _2.to_i }
    define('%') { _1.to_i % _2.to_i }
    define('^') { _1.to_i ** _2.to_i }
    define('<') { _1.to_i <  _2.to_i }
    define('≤') { _1.to_i <= _2.to_i }
    define('>') { _1.to_i >  _2.to_i }
    define('≥') { _1.to_i >= _2.to_i }
    define('=') { _1.to_i == _2.to_i }
    define('≠') { _1.to_i != _2.to_i }
    define('<=>') { _1.to_i <=> _2.to_i }
    define('chr') { _1.to_i.chr }
    define('rand'){ rand _1.to_i.._2.to_i }

    ## STRING METHODS
    define('.') { _1.to_s + _2.to_s }
    define('x') { _1.to_s * _2.to_i }
    define('lt') { _1.to_s <  _2.to_s }
    define('le') { _1.to_s <= _2.to_s }
    define('gt') { _1.to_s >  _2.to_s }
    define('ge') { _1.to_s >= _2.to_s }
    define('eq') { _1.to_s == _2.to_s }
    define('ne') { _1.to_s != _2.to_s }
    define('cmp') { _1.to_s <=> _2.to_s }
    define('substr') { _1.to_s[_2.to_i, _3.to_i] }
    define('strlen') { _1.to_s.length }
    define('ord') { _1.to_s.ord }

    ## ARRAY METHODS
    define('[]') { Scalar.new [] }
    define('get') { _1.to_a[_2.to_i] }
    define('set', push: false) { _1.to_a[_2.to_i] = _3 }
    define('del') { _1.to_a.delete_at _2.to_i }
    define('len') { _1.to_a.length }

    ## VARIABLE METHODS
    define('fetch') {
      @variables.fetch (name=name.to_s) do
        raise UnknownVariable.new name, callstack
      end
    }

    define('var') { Variable.new _1.to_s }

    ## BLOCK METHODS
    define('wrap') { Group.new pop(_1.to_i), SourceLocation.new("<constructed>", 1) }
    define 'unwrap' do 
      raise RunError, "#{_1.class} is not a Group" unless _1.is_a? Group
      _1.body
    end

    define('call', push: false) do 
      T.cast(_1, T.any(NativeFunction, Group)).call self 
    end

    ## STACK MANIPULATION
    define('dupn') { stack1.fetch -_1.to_i }
    define('popn', push: false) { stack1.delete_at -_1.to_i }
    define('dbga', push: false) { pp stack1 }
    define('dbgb', push: false) { pp stack2 }
    define('a2b', push: false) { stack2.push _1 }
    define('b2a') { stack2.pop }
    define('stacklen') { stack1.length }

    ## I/O METHODS
    define('quit') { exit _1.to_i }
    define('warn', push: false) { warn _1.to_s }
    define('print', push: false) { print _1 }
    define('println', push: false) { print _1, "\n" }
    define('getline'){ gets.chomp }
    define('system'){ `#{_1}` }
    define('read-file') { File.read _1.to_s }

    # ## VARIABLE MANIPULATION
    # define 'undef', push: false do |name|
    #   variables.delete name.to_s
    # end

    # define 'def', push: false do |name, value|
    #   variables[name.to_s] = value
    # end

    # define 'def?' do |name|
    #   variables.include? name.to_s
    # end

    ## VARIABLE MANIPULATION
    define('undef', push: false) { variables.delete _1.to_s }
    define('def', push: false) { variables[_1.to_s] = _2 }
    define('def?') { variables.include? _1.to_s }

    ## MISC METHODS
    define('kindof') { _1.class.to_s }
    define('import', push: false) do
      Stick.play File.read(filename = _1.to_s), filename, env: self
    end
=begin
    ## METHODS THAT COULD BE DEFINED NATIVELY
    define('1+') { _1.to_i + 1 }
    define('1-') { _1.to_i - 1 }
    define('2+') { _1.to_i + 2 }
    define('2-') { _1.to_i - 2 }
    define('odd?') { _1.to_i.odd? }
    define('even?') { _1.to_i.even? }
    define('zero?') { _1.to_i.zero? }
    define('nonzero?') { _1.to_i.nonzero? }
    define('dup') { self.stack1.fetch -1 }
    define('dup2') { self.stack1.fetch -2 }
    define('dup3') { self.stack1.fetch -3 }
    define('dup4') { self.stack1.fetch -4 }
    define('dupb') { self.stack2.fetch -1 }
    define('dup2b') { self.stack2.fetch -2 }
    define('pop', push: false) { self.stack1.delete_at -1 }
    define('pop2', push: false) { self.stack1.delete_at -2 }
    define('pop3', push: false) { self.stack1.delete_at -3 }
    define('pop4', push: false) { self.stack1.delete_at -4 }
    define('popb', push: false) { self.stack2.delete_at -1 }
    define('pop2b', push: false) { self.stack2.delete_at -2 }
    define('swap', push: false) { self.stack1.concat [_2, _1] }
#:swap { 2 rotn } def
#:rot { 3 rotn } def
#:rot* { rot rot } def
#:rot4 { 4 rotn } def
#:rot4* { rot4 rot4 rot4 } def
#:rot5 { 5 rotn } def
#:rot5* { rot5 rot5 rot5 rot5 } def
#:rotn { dup a2b dupn b2a 1+ popn } def
    define('void', push: false) { }
    define('{}') { Group.new [], SourceLocation.new("<constructed>", 1) }
    define('!!') { !(_1).truthy? }
    define('|') { (_1).truthy? || (_2).truthy? }
    define('||') { (_1).truthy? ? _1 : _2.call }
    define('&') { (_1).truthy? && (_2).truthy? }
    define('&&') { (_1).truthy? ? _2.call : _1 }
    define('if') { ((_1).truthy? ? _2 : _3).call }
    define('ifl') { (_1).truthy? ? _2 : _3 }
    define('while') { _2.call while (_1).truthy? }
    define('println', push: false) { print _1, "\n" }
# :alias { fetch def } def
    define('abort') { abort _1.to_s }
    define('die') { abort _1.to_s }
# :defl { 1 wrap def } def
    define('true') { 1 }
    define('false') { 0 }
    define('chars') { _1.chars.map { |x| Scalar.new x } }
    define('str-contains') { _2.to_s.include? _1.to_s[0] }
    define('apush') { _1.to_a.push _2 }

# :implode {
#   [] 
#   { dup2 } { dup dup3 3 + rotn apush swap 1- swap } while
#   pop2
# } def
# :explode {
#   0
#   { dup2 len dup2 ≠ } { dup2 dup2 get rot* 1+ } while
#   pop pop
# } def
# 
# :[ { stacklen a2b } def
# :] { stacklen b2a - implode } def
# 
# :range {
#   swap [] rot*
#   { dup2 dup2 ≥ } { dup3 dup2 apush 1+ } while
#   pop pop
# } def
# :times { 1- 0 swap range } def
# :rev {
#   []
#   { dup2 len dup2 len ≠ } {
#     dup dup3 dup
#     len dup3 len - 1-
#     get apush
#   } while
#   pop2
# } def 
# 
# ( :map {
#   swap []
#   { dup2 len dup2 len ≠ } { dup dup3 dup2 len get 5 dupn call apush } while
#   pop2 pop2
# } def )
# :map {
#   swap []
#   { dup2 len dup2 len ≠ } {
#     dup dup3 dup2 len get 5 dupn
#     ( push everything we have onto the saved stack )
#     6 rotn a2b 5 rotn a2b rot4 a2b rot a2b
#     call
#     ( remove everything from the saved stack )
#     b2a swap b2a swap b2a rot4* b2a rot5*
#     apush
#   } while
#   pop2 pop2
# } def
# 
# :foreach {
#   swap 0
#   { dup2 len dup2 ≠ } { dup2 dup2 get dup4 call 1+ } while
#   pop pop
# } def
# :reduce {
#   rot* 0 swap
#   { dup2 dup4 len ≠ } { dup3 dup3 get 5 dupn call swap 1+ swap } while
#   pop2 pop2 pop2
# } def
# :filter {
#   swap [] 0
#   { dup dup4 len ≠ } {
#     dup2 dup4 dup3 get
#     dup 7 dupn call
#     { apush } { pop pop } if
#     1+
#   } while
#   pop pop2 pop2
# } def
# 
# :sum { 0 { + } reduce } def
# :prod { 1 { * } reduce } def
# 
# :any? { map sum } def
# 
# 
# :=> :void alias
# :default { { pop true } } def ( note this is a `defl` )
# :switch { switchl call } def
# :switchl {
#   swap 0
#   { dup3 len dup2 > } {
#     dup2 dup4 dup3 get call
#     { pop2 1+ get [] swap 0 } { 2+ } if
#   } while
#   pop pop2
# } def
# 
=end
  end
end
