module Stick
  VERSION = '0.1'

  class Error < RuntimeError; end

  class RunError < Error
    attr_reader :backtrace
    def initialize(message, backtrace)
      super message

      @message = message
      @backtrace = backtrace
    end

    def full_message
      msg = "0 #{backtrace.last}: #{message}"
      backtrace[..-2].reverse.each_with_index do |idx, bt|
        msg.concat "\n#{idx} #{bt}"
      end
      msg
    end
  end

  module_function def play(*whence, env: Environment.new)
    Stick::Parser.new(*whence).parse.call env
  end
end


require_relative 'parser'
require_relative 'environment'
require_relative 'types'
