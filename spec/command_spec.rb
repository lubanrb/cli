require_relative 'spec_helper'

class TestApp
  def self.add_command(name)
    Luban::CLI::Command.new(self, name)
  end
end

describe Luban::CLI::Command do
  before do
    @cmd = TestApp.add_command(:test_cmd)
  end

  it "has a name" do
    @cmd.name.must_equal :test_cmd
  end

  it "composes command synopsis with command name" do
    @cmd.parser.banner.must_match /#{@cmd.program_name} #{@cmd.name}/
  end
end