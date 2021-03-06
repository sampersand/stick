# typed: strict
require 'sorbet-runtime'
require_relative 'stick'

return if defined? Stick::Value

module Stick
  extend T::Sig

  # Generic value type
  class Value
    extend T::Sig

    sig{ params(env: Environment).void }
    def run(env) = env.push(self)

    sig{ returns(String) }
    def to_s = raise("undefined for #{self.class}")

    sig{ returns(Integer) }
    def to_i = raise("undefined for #{self.class}")

    sig{ returns(T::Array[Value]) }
    def to_a = raise("undefined for #{self.class}")
  end

  class Scalar < Value
    sig{ params(value: T.any(Integer, String, T::Array[Value])).void }
    def initialize(value)
      @value = value
    end

    sig{ returns(String) }
    def inspect = @value.inspect

    sig{ returns(String) }
    def to_s = @value.to_s

    sig{ returns(Integer) }
    def to_i
      raise RunError, "cannot use an array as an int" if @value.is_a? Array
      @value.to_i
    end

    sig{ returns(T::Array[Value]) }
    def to_a
      raise RunError, "cannot use #{@value.class} as array" unless @value.is_a? Array
      @value
    end

    sig{ returns(T::Boolean) }
    def truthy?
      @value != '0' && @value != '' && @value != 0
    end
  end

  class NativeFunction < Value
    sig{ returns(String) }
    attr_reader :name

    sig{ params(name: String, push: T::Boolean, code: Proc).void }
    def initialize(name, push: true, &code)
      @name = name
      @code = code
      @push_result = push
      @arity = T.let @code.arity, Integer
    end

    sig{ returns(String) }
    def inspect = "NativeFunction(#@name)"

    sig{ params(env: Environment).void }
    def call(env)
      args = env.pop @arity
      result = T.unsafe(env).instance_exec(*args, &@code)
      return unless @push_result

      env.push case result
               when true then Scalar.new 1
               when false then Scalar.new 0
               when Integer, String, Array then Scalar.new result
               when Value then result
               else fail "<internal error> unknown result: #{result.inspect} for function #@name: #{args}"
               end
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
