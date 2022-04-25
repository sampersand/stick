# typed: strict
require 'sorbet-runtime'
require_relative 'stick'

return if defined? Stick::Value

module Stick
  extend T::Sig

  # Generic value type
  class Value
    extend T::Sig

    sig{ params(value: T.any(T::Boolean, Integer, String, T::Array[Value], Value)).returns(Value) }
    def self.from(value)
      case value
      when true then Scalar.new 1
      when false then Scalar.new 0
      when Integer, String then Scalar.new value
      when Array then List.new value
      when Value then value
      else T.absurd value
      end
    end

    sig{ params(env: Environment).void }
    def run(env) = env.push(self)

    sig{ returns(String) }
    def to_s = raise("#{__method__} undefined for #{self.class}")

    sig{ returns(Integer) }
    def to_i = raise("#{__method__} undefined for #{self.class}")

    sig{ returns(T::Array[Value]) }
    def to_a = raise("#{__method__} undefined for #{self.class}")
  end

  class List < Value
    sig{ returns(T::Array[Value]) }
    attr_accessor :elements

    sig{ params(elements: T::Array[Value]).void }
    def initialize(elements=[])
      @elements = elements
    end

    sig{ returns(String) }
    def inspect = @elements.inspect

    sig{ returns(String) }
    def to_s = @elements.to_s

    alias to_a elements

    sig{ params(idx: Integer).returns(T.nilable(Value)) }
    def [](idx) = @elements[idx]

    sig{ params(idx: Integer, value: Value).void }
    def []=(idx, value)
      @elements[idx] = value
    end

    sig{ params(idx: Integer).returns(T.nilable(Value)) }
    def delete_at(idx) = @elements.delete_at(idx)

    sig{ returns(Integer) }
    def length = @elements.length
  end

  class Scalar < Value
    sig{ params(value: T.any(Integer, String)).void }
    def initialize(value)
      @value = value
    end

    sig{ returns(String) }
    def inspect = @value.inspect

    sig{ returns(String) }
    def to_s = @value.to_s

    sig{ returns(Integer) }
    def to_i = @value.to_i

    sig{ returns(T::Boolean) }
    def truthy? = @value != '0' && @value != '' && @value != 0
  end

  class NativeFunction < Value
    sig{ returns(String) }
    attr_reader :name

    sig{ params(name: String, push: T::Boolean, code: Proc).void }
    def initialize(name, push: true, &code)
      @name = name
      @code = code
      @push_result = push
      @arity = T.let @code.arity - 1, Integer
    end

    sig{ returns(String) }
    def inspect = "NativeFunction(#@name)"

    sig{ params(env: Environment).void }
    def call(env)
      args = env.pop(@arity)
      result = T.unsafe(@code).call(env, *args)
      env.push Value.from result if @push_result
    end
  end

  class Group < Value
    sig{ returns(T::Array[Value]) }
    attr_reader :body

    sig{ returns(SourceLocation) }
    attr_reader :source_location

    sig{ params(body: T::Array[Value], source_location: SourceLocation).void }
    def initialize(body, source_location)
      @body = body
      @source_location = source_location
    end

    sig{ returns(String) }
    def inspect = "Group(#@source_location, #@body)"

    sig{ params(env: Environment).void }
    def call(env)
      env.with_stackframe @source_location do
        @body.each do |obj|
          obj.run env
        end
      end
    end
  end

  class Variable < Value
    sig{ returns(String) }
    attr_reader :name

    sig{ params(name: String).void }
    def initialize(name)
      @name = name
    end

    sig{ returns(String) }
    def inspect = "Variable(#@name)"

    sig{ params(env: Environment).void }
    def run(env)
      T.let(env.fetch_variable(@name), T.untyped).call(env)
    end
  end
end
