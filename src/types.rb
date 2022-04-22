# typed: strict

require 'sorbet-runtime'
require_relative 'stick'

module Stick
  extend T::Sig

  class Value
    extend T::Sig

    sig{ params(env: Environment).void }
    def run(env) = env.push(self)
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
      raise TypeError, "cannot use an array as an int" if @value.is_a? Array
      @value.to_i
    end

    sig{ returns(T::Array[Value]) }
    def to_a
      raise TypeError, "cannot use #{@value.class} as array" unless @value.is_a? Array
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

    sig{ params(name: String, env: T::Boolean, push: T::Boolean, code: Proc).void }
    def initialize(name, env: false, push: true, &code)
      @name = name
      @code = code
      @with_env = env
      @push_result = push
      @arity = T.let @code.arity - (@with_env ? 1 : 0), Integer
    end

    sig{ returns(String) }
    def inspect = "NativeFunction(#@name)"

    sig{ params(env: Environment).void }
    def call(env)
      args = @arity.times.map { env.pop }.reverse
      args.unshift env if @with_env

      result = T.unsafe(@code).call(*args)
      return unless @push_result

      env.push case result
               when true then Scalar.new 1
               when false then Scalar.new 0
               when Integer, String, Array then Scalar.new result
               when Value then result
               else fail "<internal error> unknown result: #{result} for function #@name"
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
      env.fetch_variable(@name).call(env)
    end
  end
end
