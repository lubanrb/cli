module Luban
  module CLI
    class Base
      def parse(argv=default_argv)
        argv = argv.dup
        parse!(argv)
      end

      def parse!(argv=default_argv)
        if commands.empty?
          parse_without_commands(argv)
        else
          parse_with_commands(argv)
        end
        update_result(argv)
      end

      protected

      def parse_with_commands(argv)
        parser.order!(argv)
        parse_command(argv)
      end
      alias_method :parse_posixly_correct, :parse_with_commands

      def parse_command(argv)
        cmd = argv.shift
        cmd = cmd.to_sym unless cmd.nil?
        @result[:cmd] = cmd
      end

      def parse_without_commands(argv)
        parser.permute!(argv)
        parse_arguments(argv)
      end
      alias_method :parse_permutationally, :parse_without_commands

      def parse_arguments(argv)
        @arguments.each_value do |arg|
          break if argv.empty?
          arg.value = arg.multiple? ? argv.slice!(0..-1) : argv.shift
        end
      end

      def update_result(argv)
        @result[:argv] = argv
        @result[:opts] = options.values.inject({}) { |r, o| r[o.name] = o.value; r }
        @result[:args] = arguments.values.inject({}) { |r, a| r[a.name] = a.value; r }
        @result
      end
    end
  end
end