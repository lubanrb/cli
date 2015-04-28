require 'optparse'

# Remove duplicate default options in OptionParser
# for ARGV which never appear in option summary
OptionParser::Officious.delete('help')
OptionParser::Officious.delete('version')

module Luban
  module CLI
    class Base
      include Commands

      class MissingCommand < Error; end
      class InvalidCommand < Error; end
      class MissingRequiredOptions < Error; end
      class MissingRequiredArguments < Error; end

      DefaultSummaryWidth = 32
      DefaultSummaryIndent = 4
      DefaultTitleIndent = 2

      attr_reader :app
      attr_reader :prefix
      attr_reader :program_name
      attr_reader :options
      attr_reader :arguments
      attr_reader :summary
      attr_reader :description
      attr_reader :version
      attr_reader :result
      attr_reader :default_argv

      attr_accessor :title_indent
      attr_accessor :summary_width
      attr_accessor :summary_indent

      def initialize(app, action_name, prefix: default_prefix, auto_help: true, &config_blk)
        @app = app
        @action_name = action_name
        @prefix = prefix
        @action_defined = false

        @program_name = default_program_name
        @options = {}
        @arguments = {}
        @summary = ''
        @description = ''
        @version = ''
        @default_argv = ARGV
        @result = { cmd: nil, argv: @default_argv, args: {}, opts: {} }

        @title_indent = DefaultTitleIndent
        @summary_width = DefaultSummaryWidth
        @summary_indent = DefaultSummaryIndent

        configure(&config_blk)
        setup_default_action unless @action_defined
        self.auto_help if auto_help
      end

      def default_prefix; ''; end

      def action_method
        @action_method ||= "#{@prefix}#{@action_name.to_s.gsub(':', '_')}"
      end

      def parser
        @parser ||= create_parser
      end

      def default_program_name
        @default_program_name ||= File.basename($0, '.*')
      end

      def reset
        @options.each_value { |o| o.reset }
        @arguments.each_value { |a| a.reset }
        @result = { cmd: nil, argv: @default_argv, args: {}, opts: {} }
      end

      protected

      def configure(&blk)
        config_blk = block_given? ? blk : self.class.config_blk
        instance_eval(&config_blk) unless config_blk.nil?
      end

      def setup_default_action
        method = @action_method
        action do |**opts|
          raise NotImplementedError, "#{self.class.name}##{method} is an abstract method."
        end
      end

      def dispatch_command(context, cmd:, argv:)
        validate_command(cmd)
        cmd_method = commands[cmd].action_method
        if respond_to?(cmd_method)
          send(cmd_method, argv)
        else          
          context.send(cmd_method, argv)
        end
      end

      def validate_command(cmd)
        if cmd.nil?
          raise MissingCommand, "Missing command. Expected command: #{list_commands.join(', ')}"
        end
        unless has_command?(cmd)
          raise InvalidCommand, "Invalid command. Expected command: #{list_commands.join(', ')}"
        end
      end

      def validate_required_options
        missing_opts = @options.each_value.select(&:missing?).collect(&:display_name)
        unless missing_opts.empty?
          raise MissingRequiredOptions, "Missing required option(s): #{missing_opts.join(', ')}"
        end
      end

      def validate_required_arguments
        missing_args = @arguments.each_value.select(&:missing?).collect(&:display_name)
        unless missing_args.empty?
          raise MissingRequiredArguments, "Missing required argument(s): #{missing_args.join(', ')}"
        end
      end      

      def create_parser
        @parser = OptionParser.new
        add_parser_usage
        add_parser_version unless @version.empty?
        add_parser_options unless options.empty?
        add_parser_arguments unless arguments.empty?
        add_parser_summary unless summary.empty?
        add_parser_description unless description.empty?
        add_parser_defaults unless options.values.all? { |o| o.default_str.empty? }
        add_parser_commands if has_commands?
        @parser
      end

      def add_parser_usage
        parser.banner = compose_banner
        text
      end

      def compose_banner
        "Usage: #{program_name} #{compose_synopsis}"
      end

      def compose_synopsis
        if has_commands?
          compose_synopsis_with_commands
        else
          compose_synopsis_without_commands
        end
      end

      def compose_synopsis_with_commands
        "[options] command [command options] [arguments ...]"
      end

      def compose_synopsis_without_commands
        "#{compose_synopsis_with_options}#{compose_synopsis_with_arguments}"
      end

      def compose_synopsis_with_options
        options.empty?  ? '' : '[options] '
      end

      def compose_synopsis_with_arguments
        synopsis = ''
        @arguments.each_value do |arg|
          synopsis += arg.required? ? arg.display_name : "[#{arg.display_name}]"
          synopsis += "[, #{arg.display_name}]*" if arg.multiple?
          synopsis += ' '
        end
        synopsis
      end

      def text(string = nil)
        @parser.separator(string)
      end

      def add_parser_version
        parser.version = @version
      end

      def add_parser_options
        add_section("Options") do
          @options.each_value do |option|
            parser.on(*option.specs) { |v| option.value = v }
          end
        end
      end

      def add_parser_arguments
        add_section("Arguments") do |rows|
          @arguments.each_value do |arg|
            rows.concat(summarize(arg.display_name, arg.description))
          end
        end
      end

      def add_parser_summary
        add_section("Summary", wrap(summary, summary_width * 2))
      end

      def add_parser_description
        add_section("Description", wrap(description, summary_width * 2))
      end

      def add_parser_defaults
        add_section("Defaults", options.values.map(&:default_str))
      end

      def add_parser_commands
        add_section("Commands") do |rows|
          commands.each_value do |cmd|
            rows.concat(summarize(cmd.name, cmd.summary))
          end
        end
      end

      def add_section(title, rows = [], &blk)
        text compose_title(title)
        yield rows if block_given?
        rows.each { |row| text compose_row(row) }
        text
      end

      def compose_title(title, indent = ' ' * title_indent, suffix = ':')
        "#{indent}#{title}#{suffix}"
      end

      def compose_row(string, indent = ' ' * summary_indent)
        "#{indent}#{string}"
      end

      def summarize(item, summary, width = summary_width, max_width = width - 1)
        item_rows = wrap(item.to_s, max_width)
        summary_rows = wrap(summary, max_width)
        num_of_rows = [item_rows.size, summary_rows.size].max
        rows = (0...num_of_rows).collect do |i|
                 compose_summary(item_rows[i], summary_rows[i], width)
               end
        return rows
      end

      def compose_summary(item, summary, width)
        "%-#{width}s %-#{width}s" % [item, summary]
      end

      def wrap(string, width)
        rows = []
        row = ''
        string.split(/\s+/).each do |word|
          if row.size + word.size >= width
            rows << row
            row = word
          elsif row.empty?
            row = word
          else
            row << ' ' << word
          end
        end
        rows << row if row
        rows
      end
    end
  end
end
