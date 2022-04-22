# typed: strict
module Stick
  extend T::Sig
  VERSION = '0.1'

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

  sig{ params(code: String, filename: T.nilable(String), env: Environment).void }
  module_function def play(code, filename=nil, env:)
    old_dir = Dir.pwd
    Dir.chdir File.dirname filename if filename
    Stick::Parser.new(code, filename || '<eval>').parse.call env
  ensure
    Dir.chdir T.must old_dir if filename
  end
end


require_relative 'parser'
require_relative 'environment'
require_relative 'types'
