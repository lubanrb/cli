require_relative 'spec_helper'

class TestApp
  def self.add_command(name)
    Luban::CLI::Command.new(self, name) do
      command :nested_cmd
    end
  end
end

describe Luban::CLI::Command do
  before do
    @cmd = TestApp.add_command(:test_cmd)
  end

  it "has a name" do
    @cmd.name.must_equal :test_cmd
    @cmd.commands[:nested_cmd].name.must_equal :nested_cmd
  end

  it "has a command chain" do
    @cmd.command_chain.must_equal [:test_cmd]
    @cmd.commands[:nested_cmd].command_chain.must_equal [:test_cmd, :nested_cmd]
  end

  it "has an action method defined with a proper command chain" do
    TestApp.instance_methods.include?(:__command_test_cmd)
    TestApp.instance_methods.include?(:__command_test_cmd_nested_cmd)
  end

  it "composes command synopsis with a proper command chain" do
    @cmd.parser.banner.must_match /#{@cmd.program_name} #{@cmd.name}/
    @cmd.commands[:nested_cmd].parser.banner.must_match /#{@cmd.program_name} #{@cmd.name} #{@cmd.commands[:nested_cmd].name}/
  end
end