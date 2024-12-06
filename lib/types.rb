module Value
  def run(env) = env.push(self)

  module_function def from(value)
    case value
    when true then 1
    when false then 0
    when nil then ''
    when Value then value
    else raise TypeError, "invalid type: #{value.class}"
    end
  end
end

class Integer
  include Value
end

class String
  include Value
end

class Array
  include Value
end

module Stick
  class NativeFunction
    include Value

    attr_reader :name

    def initialize(name, casts, push: true, env: false, &code)
      @name = name
      @code = code
      @push_result = push
      @send_env = env
      @casts = casts.chars
    end

    def arity
      @casts.length
    end

    def inspect = "NativeFunction(#{@name.inspect})"

    def call(env)
      args = env.pop(arity).zip(@casts).map do |arg, cast|
        case cast
        when 'i' then arg.to_i
        when 's' then arg.to_s
        when 'l' then arg.to_a
        when 'g' then arg
        when '_' then arg
        else raise "unknown cast: #{cast}"
        end
      end

      args.push env if @send_env
      result = @code.call(*args)
      env.push Value.from result if @push_result
    end
  end

  class Group
    include Value

    attr_reader :body, :location

    def initialize(body, location)
      @body = body
      @location = location
    end

    def inspect = "Group(#@location)"

    def call(env)
      env.with_stackframe @location do
        @body.each do |obj|
          obj.run env
        end
      end
    end
  end

  class Variable
    include Value

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def inspect = "Variable(#{@name.inspect})"

    def run(env)
      env.fetch_variable(@name).call(env)
    end
  end
end
