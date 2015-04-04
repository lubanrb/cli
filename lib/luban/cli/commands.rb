module Luban
  module CLI
    module Commands
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
      end

      module ClassMethods
        def inherited(subclass)
          # Ensure commands from base class
          # got inherited to its subclasses
          subclass.instance_variable_set(
            '@commands',
            Marshal.load(Marshal.dump(instance_variable_get('@commands')))
          )
          super
        end

        def commands
          @commands ||= {}
        end

        def list_commands
          commands.keys
        end

        def has_command?(cmd)
          commands.has_key?(cmd)
        end

        def has_commands?
          !commands.empty?
        end

        def command_class(cmd)
          "#{cmd.to_s.capitalize}Command"
        end

        def command(cmd, **opts, &blk)
          cmd_class = self.const_set(command_class(cmd), Class.new(Command))
          commands[cmd] = cmd_class.new(self, cmd, **opts, &blk)
        end

        def undef_command(cmd)
          commands.delete(cmd)
          undef_method(cmd)
        end
      end

      module InstanceMethods
        def commands
          self.class.commands
        end

        def list_commands
          commands.keys
        end

        def has_command?(cmd)
          self.class.has_command?(cmd)
        end

        def has_commands?
          self.class.has_commands?
        end

        def command(cmd, **opts, &blk)
          opts[:parent] = self if self.is_a?(Command)
          self.class.command(cmd, **opts, &blk)
        end

        def undef_command(cmd)
          self.class.undef_command(cmd)
        end
      end
    end
  end
end