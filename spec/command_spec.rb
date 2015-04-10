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

  it "has a parent" do
    @cmd.parent.must_be_nil
    @cmd.commands[:nested_cmd].parent.must_be_instance_of(Luban::CLI::Command)
  end

  it "composes command synopsis with a proper command chain" do
    @cmd.parser.banner.must_match /#{@cmd.program_name} #{@cmd.name}/
    @cmd.commands[:nested_cmd].parser.banner.must_match /#{@cmd.program_name} #{@cmd.name} #{@cmd.commands[:nested_cmd].name}/
  end
end