module Luban
  module CLI
    class Base
      def command(cmd, base: Command, **opts, &blk)
        cmd = cmd.to_sym
        @commands[cmd] = command_class(cmd, base).new(self, cmd, **opts, &blk)
      end

      def undef_command(cmd)
        undef_singleton_method(@commands.delete(cmd.to_sym).action_method)
      end

      def use_commands(module_name, **opts, &blk)
        module_class = Object.const_get(camelcase(module_name.to_s), false)
        module_class.constants(false).map { |c| module_class.const_get(c, false) }.each do |c|
          command(snakecase(c.name), base: c, **opts, &blk) if c < Command
        end
      end

      def list_commands
        @commands.keys
      end

      def has_command?(cmd)
        @commands.has_key?(cmd.to_sym)
      end

      def has_commands?
        !@commands.empty?
      end

      protected

      def command_class(cmd, base)
        class_name = camelcase(cmd)
        if command_class_defined?(class_name)
          get_command_class(class_name)
        else
          define_command_class(class_name, base)
        end
      end

      def command_class_defined?(class_name)
        self.class.const_defined?(class_name, false)
      end

      def get_command_class(class_name)
        self.class.const_get(class_name, false)
      end

      def define_command_class(class_name, base)
        self.class.send(:define_class, class_name, base: base, namespace: self.class)
      end

      def camelcase(str)
        str = str.to_s.dup
        str.gsub!(/(\:|\/)(.?)/){ "::#{$2.upcase}" }
        str.gsub!(/(?:_+|-+)([a-z])/){ $1.upcase }
        str.gsub!(/(\A|\s)([a-z])/){ $1 + $2.upcase }
        str
      end

      def snakecase(str)
        str.gsub(/::/, ':').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
      end
    end
  end
end
