# typed: ignore
require 'sorbet-runtime'
require_relative 'stick'

return if defined? Stick::Environment

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

    class << self
      extend T::Sig
      sig{
        params(
          name: String,
          kw: T::Boolean,
          block: T.proc.params(arg0: Environment, arg1: Value, arg2: Value, arg3: Value)
            .returns(T.untyped)
        ).void
      }
      def define(name, **kw, &block)
        DEFAULT_VARIABLES[name] = T.unsafe(Stick::NativeFunction).new(name, **kw, &block)
      end
    end


    define('println', push: false) { print _2, "\n" }
    define('dup') { T.must _1.stack1.last }
    define('1-') { _2.to_i - 1 }
    define('swap', push: false) { _1.stack1.concat [_3, _2] }
    define('&&', push: false) { 
      if T.cast(_2, Scalar).truthy?
        T.cast(_3, T.any(NativeFunction, Group)).call(_1)
      end
    }

    ## BOOLEAN METHOD
    define('!') { !T.cast(_2, Scalar).truthy? }

    ## NUMBER METHODS
    define('~') { -_2.to_i }
    define('+') { _2.to_i + _3.to_i }
    define('-') { _2.to_i - _3.to_i }
    define('*') { _2.to_i * _3.to_i }
    define('/') { _2.to_i / _3.to_i }
    define('%') { _2.to_i % _3.to_i }
    define('^') { _2.to_i ** _3.to_i }
    define('<') { _2.to_i <  _3.to_i }
    define('≤') { _2.to_i <= _3.to_i }
    define('>') { _2.to_i >  _3.to_i }
    define('≥') { _2.to_i >= _3.to_i }
    define('=') { _2.to_i == _3.to_i }
    define('≠') { _2.to_i != _3.to_i }
    define('<=>') { _2.to_i <=> _3.to_i }
    define('chr') { _2.to_i.chr }
    define('rand'){ rand _2.to_i.._3.to_i }

    ## STRING METHODS
    define('.') { _2.to_s + _3.to_s }
    define('x') { _2.to_s * _3.to_i }
    define('lt') { _2.to_s <  _3.to_s }
    define('le') { _2.to_s <= _3.to_s }
    define('gt') { _2.to_s >  _3.to_s }
    define('ge') { _2.to_s >= _3.to_s }
    define('eq') { _2.to_s == _3.to_s }
    define('ne') { _2.to_s != _3.to_s }
    define('cmp') { _2.to_s <=> _3.to_s }
    define('substr') { _2.to_s[_3.to_i, _4.to_i] }
    define('strlen') { _2.to_s.length }
    define('ord') { _2.to_s.ord }

    ## ARRAY METHODS
    define('[]') { Scalar.new [] }
    define('get') { _2.to_a[_3.to_i] }
    define('set', push: false) { _2.to_a[_3.to_i] = _4 }
    define('del') { _2.to_a.delete_at _3.to_i }
    define('len') { _2.to_a.length }

    ## VARIABLE METHODS
    define('fetch') { _1.fetch_variable _2.to_s }
    define('var') { Variable.new _2.to_s }

    ## BLOCK METHODS
    define('wrap') { Group.new _1.pop(_2.to_i), SourceLocation.new("<constructed>", 1) }
    define('unwrap') { T.cast(_2, Group).body }
    define('call', push: false) { T.cast(_2, T.any(NativeFunction, Group)).call _1 }

    ## STACK MANIPULATION
    define('dupn') { _1.stack1.fetch -_2.to_i }
    define('popn', push: false) { _1.stack1.delete_at -_2.to_i }
    define('dbga', push: false) { pp _1.stack1 }
    define('dbgb', push: false) { pp _1.stack2 }
    define('a2b', push: false) { _1.stack2.push _2 }
    define('b2a') { _1.stack2.pop }
    define('stacklen') { _1.stack1.length }

    ## I/O METHODS
    define('quit') { exit _2.to_i }
    define('warn', push: false) { warn _2.to_s }
    define('print', push: false) { print _2 }
    define('getline'){ gets.chomp }
    define('system'){ `#{_2}` }
    define('read-file') { File.read _2.to_s }

    ## VARIABLE MANIPULATION
    define('undef', push: false) { _1.delete_variable _2.to_s }
    define('def', push: false) { _1.define_variable _2.to_s, _3 }
    define('def?') { _1.variable_defined? _2.to_s }


    ## MISC METHODS
    define('kindof') { _2.class.to_s }
    define('import', push: false) do
      Stick.play File.read(filename = _2.to_s), filename, env: _1
    end

    sig{ returns(T::Array[Value]) }
    attr_reader :stack1

    sig{ returns(T::Array[Value]) }
    attr_reader :stack2

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
  end
end
