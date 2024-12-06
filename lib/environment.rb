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

    def error(message)
      raise RunError.new(message, callstack)
    end

    def self.define(name, ...)
      name = name.to_s
      DEFAULT_VARIABLES[name] = Stick::NativeFunction.new(name, ...)
    end

    ## BOOLEAN METHOD
    define :!, 's' do |string|
      string.empty? || string == '0'
    end

    ## NUMBER METHODS
    define(:~, 'i', &:-@)
    define(:+, 'ii', &:+)
    define(:-, 'ii', &:-)
    define(:*, 'ii', &:*)
    define(:/, 'ii', &:/)
    define(:%, 'ii', &:%)
    define(:^, 'ii') { Integer _1 ** _2 }
    define(:<, 'ii', &:<)
    define(:≤, 'ii', &:<=)
    define(:>, 'ii', &:>)
    define(:≥, 'ii', &:>=)
    define(:'=', 'ii', &:==)
    define(:≠, 'ii', &:!=)
    define(:<=>, 'ii', &:<=>)
    define(:chr, 'i', &:chr)
    define(:rand, 'ii') { rand _1.._2 }

    ## STRING METHODS
    define(:'.', 'ss', &:+)
    define(:x, 'si', &:*)
    define(:lt, 'ss', &:<)
    define(:le, 'ss', &:<=)
    define(:gt, 'ss', &:>)
    define(:ge, 'ss', &:>=)
    define(:eq, 'ss', &:==)
    define(:ne, 'ss', &:!=)
    define(:cmp, 'ss', &:<=>)
    define(:substr, 'sii') { _1[_2, _3] || "" }
    define(:strlen, 's', &:length)
    define(:ord, 's', &:ord)

    ## ARRAY METHODS
    define :[], '' do
      []
    end

    define :get, 'li', env: true do |list, index, env|
      list.fetch index do
        env.error "index #{index} out of bounds for list length #{list.length}"
      end
    end

    define(:set, 'li_', push: false, &:[]=)
    define :del, 'li' do |list, index|
      list.delete_at(index) || ''
    end

    define(:len, 'l', &:length)

    ## VARIABLE METHODS
    define :fetch, 's', env: true do |variable_name, env|
      env.fetch_variable variable_name
    end

    define :var, 's' do |variable_name|
      Variable.new variable_name
    end

    ## BLOCK METHODS
    define :wrap, 'i', env: true do |amnt, env|
      Group.new env.stack1.pop(amnt), SourceLocation.new("<constructed>", 1)
    end

    define :unwrap, 'g' do |group|
      raise RunError, "#{group.class} is not a Group" unless group.is_a? Group
      group.body
    end

    define(:call, '_', env: true, push: false, &:call)

    ## STACK MANIPULATION
    define(:dupn, 'i', env: true) { _2.stack1.fetch -_1 }
    define(:popn, 'i', push: false, env: true) { _2.stack1.delete_at(-_1) or fail "got out of bounds" }
    define(:dbga, '', push: false, env: true) { pp _1.stack1 }
    define(:dbgb, '', push: false, env: true) { pp _1.stack2 }
    define(:a2b, '_', push: false, env: true) { _2.stack2.push _1 }
    define(:b2a, '', env: true) { _1.stack2.pop or fail "b2a out of bounds" }
    define(:stacklen, '', env: true) { _1.stack1.length }

    ## I/O METHODS
    define(:quit, 'i') { exit _1 }
    define(:warn, 's', push: false) { warn _1; }
    define(:print, '_', push: false) { print _1; }
    define(:println, '_', push: false) { print _1, "\n"; }
    define(:getline, ''){ gets.chomp }
    define(:system, 's'){ `#{_1}` }
    define(:'read-file', 's') { File.read _1 }

    ## VARIABLE MANIPULATION
    define :undef, 's', env: true, push: false do |name, env|
      env.variables.delete name
    end

    define :def, 's_', env: true, push: false do |name, value, env|
      env.variables[name] = value
    end

    define :def?, 's', env: true do |name, env|
      env.variables.include? name
    end

    ## MISC METHODS
    define :kindof, '_' do |variable|
      case variables
      when String, Integer then 'scalar'
      when Array then 'array'
      when NativeFunction then 'native-function'
      when Group then 'group'
      when Variable then fail "shouldn't be able to get the kindof a variable?"
      else raise TypeError, "unknown kind: #{variable.class}"
      end
    end

    define :import, 's', env: true, push: false do |filename, env|
      contents = File.read filename rescue raise RunError.new("unknown file #{filename}", caller)

      Stick.play contents, filename, env: env
    end
  end
end
