require 'optparse'

# Remove duplicate default options in OptionParser
# for ARGV which never appear in option summary
OptionParser::Officious.delete('help')
OptionParser::Officious.delete('version')

module Luban
  module CLI
    class Base
      class MissingCommand < Error; end
      class InvalidCommand < Error; end
      class MissingRequiredOptions < Error; end
      class MissingRequiredArguments < Error; end

      DefaultSummaryWidth = 32
      DefaultSummaryIndent = 4
      DefaultTitleIndent = 2

      attr_reader :parent
      attr_reader :prefix
      attr_reader :program_name
      attr_reader :options
      attr_reader :arguments
      attr_reader :summary
      attr_reader :description
      attr_reader :version
      attr_reader :result
      attr_reader :default_argv
      attr_reader :commands

      attr_accessor :title_indent
      attr_accessor :summary_width
      attr_accessor :summary_indent

      def initialize(parent, action_name, prefix: default_prefix, auto_help: true, &config_blk)
        @parent = parent
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
        @commands = {}

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

      def alter(&blk)
        instance_eval(&blk)
        on_alter
      end

      protected

      def self.define_class(class_name, base:, namespace:)
        mods = class_name.split('::')
        cmd_class = mods.pop
        mods.inject(namespace) do |ns, mod|
          ns.const_set(mod, Module.new) unless ns.const_defined?(mod, false)
          ns.const_get(mod, false)
        end.const_set(cmd_class, Class.new(base))
      end

      def undef_singleton_method(method_name)
        # Undefine methods that are defined in the eigenclass
        singleton_class.send(:undef_method, method_name)
        #(class << self; self; end).send(:undef_method, method_name)
      end

      def configure(&blk)
        [self.class.config_blk, blk].each do |callback|
          instance_eval(&callback) unless callback.nil?
        end
        on_configure
      end

      def on_configure; end 
      def on_alter; end

      def setup_default_action
        if has_commands?
          action_noops
        else
          action_abort
        end
      end

      def action_noops
        action { } # NOOPS
      end

      def action_abort
        name = @action_name
        action do
          abort "Aborted! Action is NOT defined for #{name} in #{self.class.name}."
        end
      end

      def dispatch_command(cmd:, argv:)
        validate_command(cmd)
        send(commands[cmd].action_method, argv)
      end

      def invoke_action(action_method, **opts)
        handler = find_action_handler(action_method)
        if handler.nil?
          raise RuntimeError, "Action handler #{action_method} is MISSING."
        else
          handler.send(action_method, **opts)
        end
      end

      def find_action_handler(action_method)
        if respond_to?(action_method, true)
          self
        elsif @parent != self and @parent.respond_to?(:find_action_handler, true)
          @parent.send(:find_action_handler, action_method)
        else
          nil
        end
      end

      def validate_command(cmd)
        if cmd.nil?
          raise MissingCommand, "Please specify a command to execute."
        end
        unless has_command?(cmd)
          raise InvalidCommand, "Invalid command: #{cmd}"
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
        add_section("Defaults", options.values.map(&:default_str).reject { |d| d.empty? })
      end

      def add_parser_commands
        add_section("Commands") do |rows|
          commands.each_value do |cmd|
            rows.concat(summarize(cmd.name, cmd.summary, summary_width, summary_width * 1.5))
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
