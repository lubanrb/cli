$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'minitest/autorun'
require "luban/cli"

if __FILE__ == $0
  Dir.glob('./spec/**/*_spec.rb') { |f| require f }
end
