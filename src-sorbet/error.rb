# typed: strict
require 'sorbet-runtime'

module Stick
  class Error < RuntimeError; end

  class RunError < Error
    extend T::Sig

    sig{ returns(T::Array[SourceLocation]) }
    attr_reader :backtrace

    sig{ params(message: String, backtrace: T::Array[SourceLocation]).void }
    def initialize(message, backtrace)
      super message

      @message = message
      @backtrace = backtrace
    end

    sig{ returns(String) }
    def full_message
      msg = "0 #{backtrace.last}: #{message}"
      backtrace[..-2]&.reverse&.each_with_index do |idx, bt|
        msg.concat "\n#{idx} #{bt}"
      end
      msg
    end
  end
end
