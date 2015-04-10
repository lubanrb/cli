require_relative 'spec_helper'

class ACommand
  include Luban::CLI::Commands

  attr_reader :bar
  attr_reader :foo

  command(:bar) do 
    action { @status = :bar }
  end
  command(:foo) do 
    action { @foo = :foo }
  end
end

describe Luban::CLI::Commands do
  before do
    @a_cmd = ACommand.new
  end

  it "handles commands as a class" do
    ACommand.commands.each_pair do |name, cmd|
      [:bar, :foo].must_include(name)
      cmd.must_be_kind_of(Luban::CLI::Command)
    end
    ACommand.has_commands?.must_equal true
    ACommand.list_commands.must_equal [:bar, :foo]
    ACommand.has_command?(:bar).must_equal true
    ACommand.has_command?(:foo).must_equal true
  end

  it "retrieves commands as an instance" do
    @a_cmd.commands.each_pair do |name, cmd|
      [:bar, :foo].must_include(name)
      cmd.must_be_kind_of(Luban::CLI::Command)
    end
    @a_cmd.has_commands?.must_equal true
    @a_cmd.list_commands.must_equal [:bar, :foo]
    @a_cmd.has_command?(:bar).must_equal true
    @a_cmd.has_command?(:foo).must_equal true
  end

  it "can undefine command" do
    class BCommand
      include Luban::CLI::Commands
      command(:foo) do
        action { 'hi' }
      end
    end
    BCommand.has_command?(:foo).must_equal true
    BCommand.instance_methods.include?(:__command_foo).must_equal true
    BCommand.undef_command(:foo)
    BCommand.has_command?(:foo).must_equal false
    BCommand.instance_methods.include?(:__command_foo).must_equal false
  end
end