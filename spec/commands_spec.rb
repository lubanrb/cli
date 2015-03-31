require_relative 'spec_helper'

class ACommand
  include Luban::CLI::Commands

  attr_reader :bar

  command(:bar) { @status = :a }
end

class BCommand < ACommand
  attr_reader :foo

  command(:foo) { @foo = :b }
end

describe Luban::CLI::Commands do
  before do
    @a_cmd = ACommand.new
    @b_cmd = BCommand.new
  end

  it "handles commands as a class" do
    ACommand.commands.each_pair do |name, cmd|
      [:bar].must_include(name)
      cmd.must_be_instance_of(Luban::CLI::Command)
    end
    ACommand.has_commands?.must_equal true
    ACommand.list_commands.must_equal [:bar]
    ACommand.has_command?(:bar).must_equal true
    ACommand.has_command?(:foo).must_equal false

    BCommand.commands.each_pair do |name, cmd|
      [:bar, :foo].must_include(name)
      cmd.must_be_instance_of(Luban::CLI::Command)
    end
    BCommand.has_commands?.must_equal true
    BCommand.list_commands.must_equal [:bar, :foo]
    BCommand.has_command?(:bar).must_equal true
    BCommand.has_command?(:foo).must_equal true
  end

  it "retrieves commands as an instance" do
    @a_cmd.commands.each_pair do |name, cmd|
      [:bar].must_include(name)
      cmd.must_be_instance_of(Luban::CLI::Command)
    end
    @a_cmd.has_commands?.must_equal true
    @a_cmd.list_commands.must_equal [:bar]
    @a_cmd.has_command?(:bar).must_equal true
    @a_cmd.has_command?(:foo).must_equal false

    @b_cmd.commands.each_pair do |name, cmd|
      [:bar, :foo].must_include(name)
      cmd.must_be_instance_of(Luban::CLI::Command)
    end
    @b_cmd.has_commands?.must_equal true
    @b_cmd.list_commands.must_equal [:bar, :foo]
    @b_cmd.has_command?(:bar).must_equal true
    @b_cmd.has_command?(:foo).must_equal true
  end

  it "can undefine command" do
    class CCommand < BCommand
      undef_command(:foo)
    end
    CCommand.instance_methods.include?(:foo).must_equal false
    BCommand.instance_methods.include?(:foo).must_equal true
    CCommand.instance_methods.include?(:bar).must_equal true
    BCommand.instance_methods.include?(:bar).must_equal true
  end
end