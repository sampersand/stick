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
    define '!' do |scalar|
      raise RunError, "#{scalar.class} is not a scalar" unless scalar.is_a? Scalar
      !scalar.truthy?
    end

    ## NUMBER METHODS
    define('~') { -_1.to_i }
    define('+') { _1.to_i + _2.to_i }
    define('-') { _1.to_i - _2.to_i }
    define('*') { _1.to_i * _2.to_i }
    define('/') { _1.to_i / _2.to_i }
    define('%') { _1.to_i % _2.to_i }
    define('^') { Integer _1.to_i ** _2.to_i }
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
    define('substr') { _1.to_s[_2.to_i, _3.to_i] || "" }
    define('strlen') { _1.to_s.length }
    define('ord') { _1.to_s.ord }

    ## ARRAY METHODS
    define '[]' do
      List.new
    end

    define 'get' do |list, index|
      list.to_a.fetch index.to_i
    end

    define 'set', push: false do |list, index|
      list[index.to_i] = value
    end

    define 'del' do |list, index|
      list.delete_at(index.to_i) || ''
    end

    define 'len' do |list|
      list.length
    end


    # define('[]') { _1; List.new }
    # define('get') { _2.to_a.fetch _3.to_i }
    # define('set', push: false) { _2[_3.to_i] = _4 }
    # define('del') { _2.delete_at(_3.to_i) || '' }
    # define('len') { _2.length }

    ## VARIABLE METHODS
    define('fetch', env: true) { _1.fetch_variable _2.to_s }
    define('var') { Variable.new _1.to_s }

    ## BLOCK METHODS
    define 'wrap', env: true do |env, amnt|
      Group.new env.stack1.pop(amnt.to_i), SourceLocation.new("<constructed>", 1)
    end

    define 'unwrap' do |group|
      raise RunError, "#{group.class} is not a Group" unless group.is_a? Group
      group.body
    end

    define 'call', env: true, push: false do |env, block|
      block.call env
    end

    ## STACK MANIPULATION
    define('dupn', env: true) { _1.stack1.fetch -_2.to_i }
    define('popn', push: false, env: true) { _1.stack1.delete_at(-_2.to_i) or fail "got out of bounds" }
    define('dbga', push: false, env: true) { pp _1.stack1 }
    define('dbgb', push: false, env: true) { pp _1.stack2 }
    define('a2b', push: false, env: true) { _1.stack2.push _2 }
    define('b2a', env: true) { _1.stack2.pop or fail "b2a out of bounds" }
    define('stacklen', env: true) { _1.stack1.length }

    ## I/O METHODS
    define('quit') { exit _1.to_i }
    define('warn', push: false) { warn _1.to_s; }
    define('print', push: false) { print _1; }
    define('println', push: false) { print _1, "\n"; }
    define('getline'){ gets.chomp }
    define('system'){ `#{_1}` }
    define('read-file') { File.read _1.to_s }

    ## VARIABLE MANIPULATION
    define 'undef', env: true, push: false do |env, name|
      env.variables.delete name.to_s
    end

    define 'def', env: true, push: false do |env, name, value|
      env.variables[name.to_s] = value
    end

    define 'def?', env: true do |env, name|
      env.variables.include? name.to_s
    end

    ## MISC METHODS
    define('kindof') { _2.class.to_s }
    define('import', env: true, push: false) do |env, filename|
      Stick.play File.read(filename = filename.to_s), filename, env: env
    end
  end
end
