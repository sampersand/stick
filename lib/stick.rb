require_relative 'error'
require_relative 'types'
require_relative 'parser'
require_relative 'environment'

module Stick
  VERSION = '0.1'

  module_function def play(code, filename=nil, env: Environment.new)
    old_dir = Dir.pwd
    Dir.chdir File.dirname filename if filename

    Parser.new(code, filename || '<eval>').parse.call env
  ensure
    Dir.chdir old_dir if filename
  end
end

self
