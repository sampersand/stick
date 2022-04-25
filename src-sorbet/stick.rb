# typed: strict
require 'sorbet-runtime'
T::Configuration.default_checked_level = :tests

require_relative 'parser'
require_relative 'environment'
require_relative 'types'
require_relative 'error'

module Stick
  extend T::Sig
  VERSION = '0.1'

  sig{ params(code: String, filename: T.nilable(String), env: Environment).void }
  module_function def play(code, filename=nil, env:)
    old_dir = Dir.pwd
    Dir.chdir File.dirname filename if filename
    Stick::Parser.new(code, filename || '<eval>').parse.call env
  ensure
    Dir.chdir T.must old_dir if filename
  end
end
