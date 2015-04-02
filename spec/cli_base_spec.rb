require_relative 'spec_helper'

class TestCLIBase < Luban::CLI::Base
  def self.create(starter_method = :run, &config_blk)
    new(self, starter_method, &config_blk)
  end
end

class TestCLIBaseWithClassConfig < TestCLIBase
  configure { program "test_cli" }
end

class TestCLIBaseWithAction < TestCLIBase
  attr_reader :project

  protected

  def process_options(cmd:, argv:, args:, opts:)
    @project = opts[:project]
  end
end

class TestCLIBaseWithHelp < TestCLIBase
  def show_help; true; end
  def show_version; @version; end
end

def create_cli_base(klass = TestCLIBase, starter_method = :run, &config_blk)
  klass.create(starter_method, &config_blk)
end

describe Luban::CLI::Base do
  it "sets up default cli base" do
    cli = create_cli_base
    cli.program_name.must_equal cli.default_program_name
    cli.options.must_be_empty
    cli.arguments.must_be_empty
    cli.summary.must_equal ''
    cli.description.must_equal ''
    cli.version.must_equal ''
    cli.result[:cmd].must_be_nil
    cli.result[:argv] = cli.default_argv
    cli.result[:args].must_be_empty
    cli.result[:opts].must_be_empty
    cli.title_indent.must_equal Luban::CLI::Base::DefaultTitleIndent
    cli.summary_width.must_equal Luban::CLI::Base::DefaultSummaryWidth
    cli.summary_indent.must_equal Luban::CLI::Base::DefaultSummaryIndent
    assert_respond_to(cli, :run)
    assert_raises(NotImplementedError) { cli.run } 
    cli.parser.must_be_kind_of(OptionParser)
    cli.class.config_blk.must_be_nil
  end

  it "can set class configurations" do
    cli = create_cli_base(TestCLIBaseWithClassConfig)
    cli.program_name.must_equal "test_cli"
  end

  it "can set instance configurations" do
    cli = create_cli_base { program "test_cli" }
    cli.program_name.must_equal "test_cli"
    cli = create_cli_base
    cli.program_name.must_equal cli.default_program_name
  end

  it "can create help command" do
    cli = create_cli_base(TestCLIBaseWithClassConfig)
    cli.has_command?(:help).must_equal false
    class TestCLIBaseWithClassConfig < TestCLIBase
      auto_help_command
    end
    cli = create_cli_base(TestCLIBaseWithClassConfig)
    cli.has_command?(:help).must_equal true
  end

  it "sets program name" do
    cli = create_cli_base { program "test_cli" }
    cli.program_name.must_equal "test_cli"
  end

  it "sets summary" do
    cli = create_cli_base { desc "test summary" }
    cli.summary.must_equal "test summary"
  end

  it "sets description" do
    cli = create_cli_base { long_desc "test description" }
    cli.description.must_equal "test description"
  end

  it "adds an option" do
    cli = create_cli_base { option :test_opt, "test opt description" }
    cli.options.has_key?(:test_opt).must_equal true
    cli.options[:test_opt].kind.must_equal "option"
    cli.options[:test_opt].must_be_kind_of(Luban::CLI::Option)
    cli.options[:test_opt].name.must_equal :test_opt
    cli.options[:test_opt].description.must_equal "test opt description"
    # Adds a nullable option
    cli = create_cli_base { option :nullable_opt, "nullable opt description", nullable: true }
    cli.options.has_key?(:nullable_opt).must_equal true
    cli.options[:nullable_opt].kind.must_equal "nullable option"
    cli.options[:nullable_opt].must_be_kind_of(Luban::CLI::NullableOption)
    cli.options[:nullable_opt].name.must_equal :nullable_opt
    cli.options[:nullable_opt].description.must_equal "nullable opt description"
  end

  it "adds a switch" do
    cli = create_cli_base { switch :test_switch, "test switch description" }
    cli.options.has_key?(:test_switch).must_equal true
    cli.options[:test_switch].kind.must_equal "switch"
    cli.options[:test_switch].must_be_kind_of(Luban::CLI::Switch)
    cli.options[:test_switch].name.must_equal :test_switch
    cli.options[:test_switch].description.must_equal "test switch description"
    # Adds a negatable switch
    cli = create_cli_base { switch :negatable_switch, "negatable switch description", negatable: true }
    cli.options.has_key?(:negatable_switch).must_equal true
    cli.options[:negatable_switch].kind.must_equal "negatable switch"
    cli.options[:negatable_switch].must_be_kind_of(Luban::CLI::NegatableSwitch)
    cli.options[:negatable_switch].name.must_equal :negatable_switch
    cli.options[:negatable_switch].description.must_equal "negatable switch description"
  end

  it "adds an argument" do
    cli = create_cli_base { argument :test_arg, "test arg description" }
    cli.arguments.has_key?(:test_arg).must_equal true
    cli.arguments[:test_arg].kind.must_equal "argument"
    cli.arguments[:test_arg].must_be_kind_of(Luban::CLI::Argument)
    cli.arguments[:test_arg].name.must_equal :test_arg
    cli.arguments[:test_arg].description.must_equal "test arg description"
  end

  it "adds help" do
    [:help, :auto_help].each do |meth|
      # Adds help with default parameters
      cli = create_cli_base { send(meth) }
      cli.options.has_key?(:help).must_equal true
      cli.options[:help].kind.must_equal "switch"
      cli.options[:help].must_be_kind_of(Luban::CLI::Switch)
      cli.options[:help].name.must_equal :help
      cli.options[:help].description.must_equal "Show this help message."
      cli.options[:help][:short].must_equal :h      
      # Adds help with customized parameters
      cli = create_cli_base { send(meth, short: :i, desc: "Show this help info.") }
      cli.options.has_key?(:help).must_equal true
      cli.options[:help].description.must_equal "Show this help info."
      cli.options[:help][:short].must_equal :i
    end
  end

  it "manages version" do
    # Adds version with default parameters
    cli = create_cli_base { version '1.0.0' }
    cli.version.must_equal '1.0.0'
    cli.options.has_key?(:version).must_equal true
    cli.options[:version].kind.must_equal "switch"
    cli.options[:version].must_be_kind_of(Luban::CLI::Switch)
    cli.options[:version].name.must_equal :version
    cli.options[:version].description.must_equal "Show #{cli.program_name} version."
    cli.options[:version][:short].must_equal :v
    # Adds version with customized parameters
    cli = create_cli_base { version '1.0.0', short: :s, desc: "Show version." }
    cli.version.must_equal '1.0.0'
    cli.options.has_key?(:version).must_equal true
    cli.options[:version].kind.must_equal "switch"
    cli.options[:version].must_be_kind_of(Luban::CLI::Switch)
    cli.options[:version].name.must_equal :version
    cli.options[:version].description.must_equal "Show version."
    cli.options[:version][:short].must_equal :s
  end

  it "shows help and version" do
    cli = create_cli_base(TestCLIBaseWithHelp) { version '1.0.0'; auto_help }
    cli.run(["--help"]).must_equal true
    cli.reset
    cli.run(["--version"]).must_equal '1.0.0'
  end


  it "specifies action block" do
    project = nil
    cli = create_cli_base(TestCLIBaseWithAction) do
            option :project, "project name"
            action do |cmd:, argv:, args:, opts:|
              project = opts[:project]
            end
          end
    argv = ["--project", "test project"]
    cli.run(argv)
    project.must_equal "test project"
  end

  it "specifies action method" do
    cli = create_cli_base(TestCLIBaseWithAction) do
            option :project, "project name"
            action(:process_options)
          end
    argv = ["--project", "test project"]
    cli.run(argv)
    cli.project.must_equal "test project"
  end

  it "raises exception if neither action block nor action method is given" do
    assert_raises(ArgumentError) do
      create_cli_base(TestCLIBaseWithAction) { action }
    end
  end

  it "specifies action with preserving arguments during parsing" do
    cli = create_cli_base(TestCLIBaseWithAction) do
            option :project, "project name"
            action(:process_options)
          end
    argv = ["--project", "test project"]
    origin_argv = argv.clone
    cli.run(argv)
    cli.project.must_equal "test project"
    argv.must_equal origin_argv
  end

  it "specifies action without preserving arguments during parsing" do
    cli = create_cli_base(TestCLIBaseWithAction) do
            option :project, "project name"
            action!(:process_options)
          end
    argv = ["--project", "test project"]
    origin_argv = argv.clone
    cli.run(argv)
    cli.project.must_equal "test project"
    argv.wont_equal origin_argv
    argv.must_be_empty
  end

  it "resets options and arguments" do
    cli = create_cli_base(TestCLIBaseWithAction) do
            option :project, "project name"
            argument :manager, "project manager"
            action!(:process_options)
          end
    argv = ["--project", "test project", "John Smith"]
    cli.run(argv)
    cli.project.must_equal "test project"
    cli.options[:project].value.must_equal "test project"
    cli.arguments[:manager].value.must_equal "John Smith"
    cli.result[:opts][:project].must_equal "test project"
    cli.result[:args][:manager].must_equal "John Smith"
    cli.reset
    cli.options[:project].value.must_equal nil
    cli.arguments[:manager].value.must_equal nil
    cli.result[:opts][:project].must_equal nil
    cli.result[:args][:manager].must_equal nil
  end
end