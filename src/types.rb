require_relative 'stick'

module Stick
  class Value
    def run(env) = env.push(self)
  end

  class Scalar < Value
    def initialize(value)
      @value = value
    end

    def inspect = @value.inspect

    def to_s = @value.to_s
    def to_i = @value.to_i
    def to_a = @value.to_a

    def truthy?
      @value != '0' && @value != '' && @value != 0
    end
  end

  class NativeFunction < Value
    attr_reader :name

    def initialize(name, env: false, push: true, &code)
      @name = name
      @code = code
      @with_env = env
      @push_result = push
      @arity = code.arity - (@with_env ? 1 : 0)
    end

    def inspect = "NativeFunction(#@name)"

    def call(env)
      args = @arity.times.map { env.pop }.reverse
      args.unshift env if @with_env

      result = @code.call(*args)
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
    attr_reader :body, :source_location

    def initialize(body, source_location)
      @body = body
      @source_location = source_location
    end

    def inspect = "Group(#@source_location, #@body)"

    def call(env)
      env.with_stackframe @source_location do
        @body.each do |obj|
          obj.run env
        end
      end
    end
  end

  class Variable < Value
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def inspect = "Variable(#@name)"

    def run(env)
      env.fetch_variable(@name).call(env)
    end
  end
end
