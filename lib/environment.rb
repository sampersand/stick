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
    define '!', '_' do |scalar|
      raise RunError, "#{scalar.class} is not a scalar" unless scalar.is_a? Scalar
      !scalar.truthy?
    end

    ## NUMBER METHODS
    define('~', 'i', &:-@)
    define('+', 'ii', &:+)
    define('-', 'ii', &:-)
    define('*', 'ii', &:*)
    define('/', 'ii', &:/)
    define('%', 'ii', &:%)
    define('^', 'ii') { Integer _1 ** _2 }
    define('<', 'ii', &:<)
    define('≤', 'ii', &:<=)
    define('>', 'ii', &:>)
    define('≥', 'ii', &:>=)
    define('=', 'ii', &:==)
    define('≠', 'ii', &:!=)
    define('<=>', 'ii', &:<=>)
    define('chr', 'i', &:chr)
    define('rand', 'ii') { rand _1.._2 }

    ## STRING METHODS
    define('.', 'ss', &:+)
    define('x', 'si', &:*)
    define('lt', 'ss', &:<)
    define('le', 'ss', &:<=)
    define('gt', 'ss', &:>)
    define('ge', 'ss', &:>=)
    define('eq', 'ss', &:==)
    define('ne', 'ss', &:!=)
    define('cmp', 'ss', &:<=>)
    define('substr', 'sii') { _1[_2, _3] || "" }
    define('strlen', 's', &:length)
    define('ord', 's', &:ord)

    ## ARRAY METHODS
    define '[]', '' do
      List.new
    end

    define 'get', 'li' do |list, index|
      list.fetch index
    end

    define 'set', 'li_', push: false do |list, index, value|
      list[index] = value
    end

    define 'del', 'li' do |list, index|
      list.delete_at(index) || ''
    end

    define 'len', 'l' do |list|
      list.length
    end

    ## VARIABLE METHODS
    define('fetch', 's', env: true) { _2.fetch_variable _1 }
    define('var', 's') { Variable.new _1 }

    ## BLOCK METHODS
    define 'wrap', 'i', env: true do |amnt, env|
      Group.new env.stack1.pop(amnt), SourceLocation.new("<constructed>", 1)
    end

    define 'unwrap', '_' do |group|
      raise RunError, "#{group.class} is not a Group" unless group.is_a? Group
      group.body
    end

    define 'call', '_', env: true, push: false do |block, env|
      block.call env
    end

    ## STACK MANIPULATION
    define('dupn', 'i', env: true) { _2.stack1.fetch -_1 }
    define('popn', 'i', push: false, env: true) { _2.stack1.delete_at(-_1) or fail "got out of bounds" }
    define('dbga', '', push: false, env: true) { pp _1.stack1 }
    define('dbgb', '', push: false, env: true) { pp _1.stack2 }
    define('a2b', '_', push: false, env: true) { _2.stack2.push _1 }
    define('b2a', '', env: true) { _1.stack2.pop or fail "b2a out of bounds" }
    define('stacklen', '', env: true) { _1.stack1.length }

    ## I/O METHODS
    define('quit', 'i') { exit _1 }
    define('warn', 's', push: false) { warn _1; }
    define('print', '_', push: false) { print _1; }
    define('println', '_', push: false) { print _1, "\n"; }
    define('getline', ''){ gets.chomp }
    define('system', 's'){ `#{_1}` }
    define('read-file', 's') { File.read _1 }

    ## VARIABLE MANIPULATION
    define 'undef', 's', env: true, push: false do |name, env|
      env.variables.delete name
    end

    define 'def', 's_', env: true, push: false do |name, value, env|
      env.variables[name] = value
    end

    define 'def?', 's', env: true do |name, env|
      env.variables.include? name
    end

    ## MISC METHODS
    define('kindof', '_') { _1.class.to_s }
    define('import', 's', env: true, push: false) do |filename, env|
      Stick.play File.read(filename), filename, env: env
    end
  end
end
