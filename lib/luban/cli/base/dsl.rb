module Luban
  module CLI
    class Base
      class << self
        def inherited(subclass)
          super
          # Ensure configuration block from base class
          # got inherited to its subclasses
          blk = instance_variable_get('@config_blk')
          subclass.instance_variable_set('@config_blk', blk.clone) unless blk.nil?
        end

        attr_reader :config_blk

        def configure(&blk); @config_blk = blk; end
      end

      def program(name)
        @program_name = name.to_s unless name.nil? 
      end

      def desc(string)
        @summary = string.to_s unless string.nil?
      end

      def long_desc(string)
        @description = string.to_s unless string.nil?
      end

      def option(name, desc, nullable: false, **config, &blk)
        @options[name] = if nullable
                           NullableOption.new(name, desc, **config, &blk)
                         else
                           Option.new(name, desc, **config, &blk)
                         end
      end

      def switch(name, desc, negatable: false, **config, &blk)
        @options[name] = if negatable
                           NegatableSwitch.new(name, desc, **config, &blk)
                         else
                           Switch.new(name, desc, **config, &blk)
                         end
      end

      def argument(name, desc, **config, &blk)
        @arguments[name] = Argument.new(name, desc, **config, &blk)
      end

      def help(short: :h, desc: "Show this help message.", &blk)
        switch :help, desc, short: short, &blk
      end
      alias_method :auto_help, :help

      def show_help; puts parser.help; end

      def show_help_for_command(args:, **params)
        if args[:command].nil?
          show_help
        else
          commands[args[:command]].show_help
        end
      end

      def help_command(**opts, &blk)
        if block_given?
          command(**opts, &blk)
        else
          validator = method(:has_command?)
          command(:help, **opts) do
            desc "List all commands or help for one command"
            argument :command, "Command to help for", 
                      type: :symbol, required: false,
                     assure: validator
            action :show_help_for_command
          end
        end
      end
      alias_method :auto_help_command, :help_command

      def version(ver = nil, short: :v, desc: "Show #{program_name} version.", &blk)
        if ver.nil?
          @version
        else
          @version = ver.to_s
          switch :version, desc, short: short, &blk
        end
      end

      def show_version; puts parser.ver; end

      def action(method_name = nil, &blk)
        create_action(method_name, preserve_argv: true, &blk)
      end

      def action!(method_name = nil, &blk)
        create_action(method_name, preserve_argv: false, &blk)
      end

      protected

      def create_action(method_name = nil, preserve_argv: true, &blk)
        handler = if method_name
                    lambda { |**opts| invoke_action(method_name, **opts) }
                  elsif block_given?
                    blk
                  end
        if handler.nil?
          raise ArgumentError, "Code block to execute command #{@action_name} is MISSING."
        end
        _base = self
        parse_method = preserve_argv ? :parse : :parse!
        define_action_method do |argv = _base.default_argv|
          _base.send(:process, parse_method, argv) do |params|
            instance_exec(**params, &handler)
          end
        end
        @action_defined = true
      end

      def define_action_method(&action_blk)
        @parent.send(:define_singleton_method, action_method, &action_blk)
      end

      def process(parse_method, argv)
        send(parse_method, argv)
        if result[:opts][:help]
          show_help
        elsif !@version.empty? and result[:opts][:version]
          show_version
        else
          validate_required_options
          validate_required_arguments
          result[:opts][:__remaining__] = argv
          yield args: result[:args], opts: result[:opts]
          if has_commands?
            dispatch_command(cmd: result[:cmd], argv: result[:argv])
          end
        end
      rescue OptionParser::ParseError, Error => e
        on_parse_error(e)
      end

      def on_parse_error(error)
        show_error_and_exit(error)
      end

      def show_error_and_exit(error)
        show_error(error)
        show_help
        exit 64 # Linux standard for bad command line
      end

      def show_error(error)
        puts "#{error.message} (#{error.class.name})"
        puts
      end
    end
  end
end
