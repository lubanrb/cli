$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')
require 'minitest/autorun'
require "luban/cli"

if __FILE__ == $0
  Dir.glob('./spec/**/*_spec.rb') { |f| require f }
end