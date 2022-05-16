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

    attr_reader :stack1, :stack2, :variables

    def initialize
      @stack1 = []
      @stack2 = []
      @variables = DEFAULT_VARIABLES.dup

      @callstack = []
    end

    def with_stackframe(frame, &block)
      @callstack.push frame
      block.call
    ensure
      @callstack.pop
    end

    def push(value) = @stack1.push(value)
    def pop(...) = @stack1.pop(...)
    def popn(n)
      @stack1.delete_at(~n) or raise RunError, "pop out of bounds, max #{@stack1.length}, given #{n}"
    end

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

    def self.define(name, ...)
      DEFAULT_VARIABLES[name] = Stick::NativeFunction.new(name, ...)
    end

    def self.define_with_env(name, &block)
      DEFAULT_VARIABLES[name] = Stick::NativeFunction.new(name, push: false, &block)
    end

    ## BOOLEAN METHOD
    define '!' do
      raise RunError, "#{_2.class} is not a scalar" unless _2.is_a? Scalar
      !_2.truthy?
    end

    ## NUMBER METHODS
    define('~') { -_2.to_i }
    define('+') { _2.to_i + _3.to_i }
    define('-') { _2.to_i - _3.to_i }
    define('*') { _2.to_i * _3.to_i }
    define('/') { _2.to_i / _3.to_i }
    define('%') { _2.to_i % _3.to_i }
    define('^') { Integer _2.to_i ** _3.to_i }
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
    define('substr') { _2.to_s[_3.to_i, _4.to_i] || "" }
    define('strlen') { _2.to_s.length }
    define('ord') { _2.to_s.ord }

    ## ARRAY METHODS
    define '[]' do |_env|
      List.new
    end

    define 'get' do |_env, list, index|
      list.to_a.fetch index.to_i
    end

    define 'set', push: false do |_env, list, index|
      list[index.to_i] = value
    end

    define 'del' do |env, list, index|
      list.delete_at(index.to_i) || ''
    end

    define 'len' do |_env, list|
      list.length
    end


    # define('[]') { _1; List.new }
    # define('get') { _2.to_a.fetch _3.to_i }
    # define('set', push: false) { _2[_3.to_i] = _4 }
    # define('del') { _2.delete_at(_3.to_i) || '' }
    # define('len') { _2.length }

    ## VARIABLE METHODS
    define('fetch') { _1.fetch_variable _2.to_s }
    define('var') { Variable.new _2.to_s }

    ## BLOCK METHODS
    define('wrap') { Group.new _1.stack1.pop(_2.to_i), SourceLocation.new("<constructed>", 1) }
    define 'unwrap' do 
      raise RunError, "#{_2.class} is not a Group" unless _2.is_a? Group
      _2.body
    end

    define('call', push: false) do 
      _2.call _1
      0
    end

    ## STACK MANIPULATION
    define('dupn') { _1.stack1.fetch -_2.to_i }
    define('popn', push: false) { _1.stack1.delete_at(-_2.to_i) or fail "got out of bounds" }
    define('dbga', push: false) { pp _1.stack1 }
    define('dbgb', push: false) { pp _1.stack2 }
    define('a2b', push: false) { _1.stack2.push _2 }
    define('b2a') { _1.stack2.pop or fail "b2a out of bounds" }
    define('stacklen') { _1.stack1.length }

    ## I/O METHODS
    define('quit') { exit _2.to_i }
    define('warn', push: false) { warn _2.to_s; 0 }
    define('print', push: false) { print _2; 0 }
    define('println', push: false) { print _2, "\n"; 0 }
    define('getline'){ gets.chomp }
    define('system'){ `#{_2}` }
    define('read-file') { File.read _2.to_s }

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
    define('undef', push: false) { _1.variables.delete _2.to_s; 0 }
    define('def', push: false) { _1.variables[_2.to_s] = _3 }
    define('def?') { _1.variables.include? _2.to_s }

    ## MISC METHODS
    define('kindof') { _2.class.to_s }
    define('import', push: false) do
      Stick.play File.read(filename = _2.to_s), filename, env: _1
    end
  end
end
