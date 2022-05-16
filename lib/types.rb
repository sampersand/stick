module Stick
  # Generic value type
  class Value
    def self.from(value)
      case value
      when true then Scalar.new 1
      when false then Scalar.new 0
      when Integer, String then Scalar.new value
      when Array then List.new value
      when Value then value
      else raise TypeError, "invalid value type: #{value.class}"
      end
    end

    def run(env) = env.push(self)

    def to_s = raise("#{__method__} undefined for #{self.class}")
    def to_i = raise("#{__method__} undefined for #{self.class}")
    def to_a = raise("#{__method__} undefined for #{self.class}")
  end

  class Scalar < Value
    def initialize(value)
      @value = value
    end

    def inspect = @value.inspect
    def to_s = @value.to_s
    def to_i = @value.to_i
    def truthy? = @value != '0' && @value != '' && @value != 0
  end

  class List < Value
    attr_accessor :elements

    def initialize(elements=[])
      @elements = elements
    end

    def inspect = @elements.inspect
    def to_s = @elements.to_s

    alias to_a elements

    def [](idx) = @elements[idx]
    def []=(idx, value)
      @elements[idx] = value
    end

    def delete_at(idx) = @elements.delete_at(idx)
    def length = @elements.length
  end

  class NativeFunction < Value
    attr_reader :name, :arity

    def initialize(name, push: true, env: false, &code)
      @name = name
      @code = code
      @push_result = push
      @send_env = env
      @arity = @code.arity - (env ? 1 : 0)
    end

    def inspect = "NativeFunction(#{@name.inspect})"
    def call(env)
      args = env.pop(@arity)
      args.unshift env if @send_env
      result = @code.call(*args)
      env.push Value.from result if @push_result
    end
  end

  class Group < Value
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

  class Variable < Value
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
