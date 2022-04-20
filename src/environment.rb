require_relative 'stick'

module Stick
  class Environment
    class UnknownVariable < RunError
      attr_reader :name
      def initialize(name, callstack)
        super "undefined variable #{name.inspect}", callstack
        @name = name
      end
    end

    DEFAULT_VARIABLES = {}
    def self.define(name, ...)
      DEFAULT_VARIABLES[name] = Stick::NativeFunction.new(name, ...)
    end

    ## BOOLEAN METHOD
    define('!') { !_1.truthy? }

    ## NUMBER METHODS
    define('+') { _1.to_i + _2.to_i }
    define('-') { _1.to_i - _2.to_i }
    define('*') { _1.to_i * _2.to_i }
    define('/') { _1.to_i / _2.to_i }
    define('%') { _1.to_i % _2.to_i }
    define('<') { _1.to_i <  _2.to_i }
    define('≤') { _1.to_i <= _2.to_i }
    define('>') { _1.to_i >  _2.to_i }
    define('≥') { _1.to_i >= _2.to_i }
    define('=') { _1.to_i == _2.to_i }
    define('≠') { _1.to_i != _2.to_i }
    define('<=>') { _1.to_i <=> _2.to_i }
    define('num2ascii') { _1.to_i.chr }
    define('rand'){ rand _1.to_i.._2.to_i }

    ## STRING METHODS
    define('.') { _1.to_s + _2.to_s }
    define('x') { _1.to_s * _2.to_i }
    define('le') { _1.to_s <  _2.to_s }
    define('le') { _1.to_s <= _2.to_s }
    define('gt') { _1.to_s >  _2.to_s }
    define('ge') { _1.to_s >= _2.to_s }
    define('eq') { _1.to_s == _2.to_s }
    define('ne') { _1.to_s != _2.to_s }
    define('cmp') { _1.to_s <=> _2.to_s }
    define('substr') { _1.to_s[_2.to_i, _3.to_i] }
    define('strlen') { _1.to_s.length }
    define('ascii2num') { _1.to_s.ord }

    ## ARRAY METHODS
    define('[]') { Scalar.new [] }
    define('get') { _1.to_a[_2.to_i] }
    define('set') { _1.to_a[_2.to_i] = _3 }
    define('del') { _1.delete_at _2.to_i }
    define('len') { _1.length }

    ## VARIABLE METHODS
    define('fetch', env: true) { _1.fetch_variable _2 }
    define('var') { Variable.new _1.to_s }

    ## BLOCK METHODS
    define('wrap', env: true) { Group.new _1.pop(_2.to_i), "<constructed>" }
    define('unwrap') { _1.body }
    define('call', env: true, push: false) { _2.call _1 }

    ## STACK MANIPULATION
    define('dupn', env: true) { _1.stack1.fetch -_2.to_i }
    define('popn', env: true) { _1.stack1.delete_at -_2.to_i }
    define('dbga', env: true, push: false) { pp _1.stack1 }
    define('dbgb', env: true, push: false) { pp _1.stack2 }
    define('a2b', env: true, push: false) { _1.stack2.push _2 }
    define('b2a', env: true) { _1.stack2.pop }

    ## I/O METHODS
    define('quit') { exit _1.to_i }
    define('warn', push: false) { warn _1 }
    define('print', push: false) { print _1 }
    define('println', push: false) { print _1, "\n" }
    define('getline'){ gets.chomp }
    define('system'){ `#{_1}` }
    define('read-file') { File.read _1.to_s }

    ## VARIABLE MANIPULATION
    define('undef', env: true, push: false) { _1.delete_variable _2 }
    define('def', env: true, push: false) { _1.define_variable _2, _3 }
    define('def?', env: true) { _1.variable_defined? _2 }

    ## MISC METHODS
    define('kindof') { _1.class.to_s }
    define('import', env: true, push: false) do
      Stick.play File.read(filename = _2.to_s), filename, env: _1
    end

    define('ret') { throw :ret, _1.to_i }

    attr_reader :stack1, :stack2

    def initialize
      @stack1 = []
      @stack2 = []
      @variables = DEFAULT_VARIABLES.dup

      @callstack = []
    end

    def with_stackframe(frame)
      @callstack.push frame
      yield
    ensure
      @callstack.pop
    end

    def push(value) = @stack1.push(value || fail("internal error: n is nil"))
    def pop(...) = @stack1.pop(...)
    def popn(n) = @stack1.delete_at(~n)

    def delete_variable(name)
      @variables.delete name.to_s
    end

    def define_variable(name, value)
      @variables[name.to_s] = value
    end

    def variable_defined?(name)
      @variables.include? name.to_s
    end

    def callstack = @callstack.clone

    def fetch_variable(name)
      @variables.fetch (name=name.to_s) do
        raise UnknownVariable.new name, callstack
      end
    end
  end
end
