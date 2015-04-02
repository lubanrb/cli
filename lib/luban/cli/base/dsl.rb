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
        _base = self
        parse_method = preserve_argv ? :parse : :parse!
        @app.define_singleton_method(@starter_method) do |argv=_base.default_argv|
          _base.send(parse_method, argv)
          begin
            if _base.result[:opts][:help]
              _base.show_help
            elsif _base.result[:opts][:version]
              _base.show_version
            else
              _base.validate_required_options
              _base.validate_required_arguments
              instance_exec(**_base.result, &handler)
            end
          rescue OptionParser::ParseError, Error => e
            _base.on_parse_error(e)
          end
        end
        @action_defined = true
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
