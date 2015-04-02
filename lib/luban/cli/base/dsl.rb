module Luban
  module CLI
    class Base
      include Commands

      class << self
        attr_reader :config_blk
        
        def configure(&blk); @config_blk = blk; end

        def help_command(auto_help: true, &blk)
          if block_given?
            command(:help, &blk)
          else
            command(:help) do
              desc "List all commands or help for one command"
              argument :command, "Command to help for", 
                       type: :symbol, required: false
              self.auto_help if auto_help
              action :show_help_for_command
            end
          end
        end
        alias_method :auto_help_command, :help_command
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
                    lambda { |**opts| send(method_name, **opts) }
                  elsif block_given?
                    blk
                  end
        if handler.nil?
          raise ArgumentError, "Code block to execute command #{@starter_method} is MISSING."
        end
        _command = self
        parse_method = preserve_argv ? :parse : :parse!
        @app_class.send(:define_method, @starter_method) do |argv=_command.default_argv|
          _command.send(parse_method, argv)
          if _command.result[:opts][:help]
            _command.show_help
          elsif _command.result[:opts][:version]
            _command.show_version
          else
            instance_exec(**_command.result, &handler)
          end
        end
      end
    end
  end
end