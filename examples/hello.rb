$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')
require 'luban/cli'

class HelloApp < Luban::CLI::Application
  HelloTexts = { english: 'Hello', french: 'Bonjour',
                 german: 'Halo', italian: 'Ciao',
                 chinese: '您好', japanese: 'こんにちは',
                 korean: '안녕하세요' }
  Languages = HelloTexts.keys

  configure do
    # program "hello"
    version '1.0.0'
    desc "Say hello to someone"
    long_desc "Demo app for Luban::CLI"
    option :lang, "Language to say hello", short: :l,
           type: :symbol, default: :english, within: Languages
    switch :verbose, "Run in verbose mode", short: :V 
    argument :name, "Name to say hello"
    action :say_hello
  end

  def say_hello(args:, opts:)
    hello_text = HelloTexts[opts[:lang]]
    name = args[:name]
    if opts[:verbose]
      say_hello_verbosely(hello_text, name, opts, args)
    else
      say_hello_concisely(hello_text, name)
    end
  end

  protected

  def say_hello_verbosely(hello_text, name, opts, args)
    puts "Options: #{opts.inspect}"
    puts "Arguments: #{args.inspect}"
    say_hello_concisely(hello_text, name)
  end

  def say_hello_concisely(hello_text, name)
    puts "#{hello_text}, #{name}!"
  end
end

HelloApp.new.run
