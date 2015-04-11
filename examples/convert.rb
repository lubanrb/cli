$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')
require 'luban/cli'

class ConvertApp < Luban::CLI::Application
  configure do
    version '1.0.0'
    desc 'Convert on simple Ruby objects'
    long_desc 'Demo app for Luban::CLI'
  end

  auto_help_command

  command :text do
    desc 'Manipulate texts'

    command :capitalize do
      desc 'capitalize a given string'
      argument :str, type: :string
      action :capitalize_string
    end

    command :join do
      desc 'Concat a given strings with a specified delimiter'
      option :delimiter, 'Delimiter to join strings', short: :d, default: ', '
      argument :strs, 'Strings to be joined', type: :string, multiple: true
      action :join_strings
    end
  end

  command :number do
    desc 'Manipulate numbers'

    command :rationalize do
      desc 'Return a simpler approximation of the value within an optional specified precision'
      option :precision, 'Epsilon for the approximation', short: :p, type: :float
      argument :value, 'Floating point number to be rationalized', type: :float
      action :rationalize_number
    end

    command :round do
      desc 'Rounds the given number to a specified precision in decimal digits'
      option :digits, 'Precision in decimal digits', short: :d, type: :integer, required: true
      argument :value, 'Floating point number to be rounded', type: :float
      action :round_number
    end
  end

  def capitalize_string(args:, **others)
    puts "Capitalize the given string #{args[:str].inspect}:"
    puts args[:str].capitalize
  end

  def join_strings(args:, opts:, **others)
    puts "Join strings #{args[:strs].inspect} with #{opts[:delimiter].inspect}:"
    puts args[:strs].join(opts[:delimiter])
  end

  def rationalize_number(args:, opts:, **others)
    if opts[:precision].nil?
      puts "Rationalize value #{args[:value]}:"
      puts args[:value].rationalize  
    else
      puts "Rationalize value #{args[:value]} with precision #{opts[:precision]}:"
      puts args[:value].rationalize(opts[:precision])
    end
  end

  def round_number(args:, opts:, **others)
    puts "Round value #{args[:value]} with precision in #{opts[:digits]} decimal digits"
    puts args[:value].round(opts[:digits])
  end
end

ConvertApp.new.run