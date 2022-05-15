require_relative 'parser'
require_relative 'environment'
require_relative 'types'
require_relative 'error'

module Stick
  VERSION = '0.1'

  module_function def play(code, filename=nil, env:)
    old_dir = Dir.pwd
    Dir.chdir File.dirname filename if filename
    Stick::Parser.new(code, filename || '<eval>').parse.call env
  ensure
    Dir.chdir old_dir if filename
  end
end

self
