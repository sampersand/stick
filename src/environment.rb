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
    define('[]') { _1; List.new }
    define('get') { _2.to_a.fetch _3.to_i }
    define('set', push: false) { _2[_3.to_i] = _4 }
    define('del') { _2.delete_at(_3.to_i) || '' }
    define('len') { _2.length }

    ## VARIABLE METHODS
    define('fetch') { _1.fetch_variable _2.to_s }
    define('var') { Variable.new _2.to_s }

    ## BLOCK METHODS
    define('wrap') { Group.new _1.stack1.pop(_2.to_i), SourceLocation.new(filename: "<constructed>", lineno: 1) }
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
      0
    end
=begin
    ## METHODS THAT COULD BE DEFINED NATIVELY
    define('1+') { _2.to_i + 1 }
    define('1-') { _2.to_i - 1 }
    define('2+') { _2.to_i + 2 }
    define('2-') { _2.to_i - 2 }
    define('odd?') { _2.to_i.odd? }
    define('even?') { _2.to_i.even? }
    define('zero?') { _2.to_i.zero? }
    define('nonzero?') { _2.to_i.nonzero? }
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
    define('swap', push: false) { self.stack1.concat [_3, _2] }
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
    define('!!') { !(_2).truthy? }
    define('|') { (_2).truthy? || (_3).truthy? }
    define('||') { (_2).truthy? ? _2 : _3.call }
    define('&') { (_2).truthy? && (_3).truthy? }
    define('&&') { (_2).truthy? ? _3.call : _2 }
    define('if') { ((_2).truthy? ? _3 : _4).call }
    define('ifl') { (_2).truthy? ? _3 : _4 }
    define('while') { _3.call while (_2).truthy? }
    define('println', push: false) { print _2, "\n" }
# :alias { fetch def } def
    define('abort') { abort _2.to_s }
    define('die') { abort _2.to_s }
# :defl { 1 wrap def } def
    define('true') { 1 }
    define('false') { 0 }
    define('chars') { _2.chars.map { |x| Scalar.new x } }
    define('str-contains') { _3.to_s.include? _2.to_s[0] }
    define('apush') { _2.to_a.push _3 }

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
