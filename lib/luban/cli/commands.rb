module Luban
  module CLI
    module Commands
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
      end

      module CommonMethods
        def list_commands
          commands.keys
        end

        def has_command?(cmd)
          commands.has_key?(cmd)
        end

        def has_commands?
          !commands.empty?
        end
      end

      module ClassMethods
        include CommonMethods

        def commands
          @commands ||= {}
        end

        def command_class(cmd)
          "#{classify(cmd)}Command"
        end

        def command(cmd, **opts, &blk)
          cmd_class = command_class(cmd)
          klass = if self.const_defined?(command_class(cmd))
                    self.const_get(command_class(cmd))
                  else
                    self.const_set(command_class(cmd), Class.new(Command))
                  end
          commands[cmd] = klass.new(self, cmd, **opts, &blk)
        end

        def undef_command(cmd)
          undef_method(commands.delete(cmd).action_method)
        end

        protected

        def classify(cmd)
          cmd = cmd.to_s.dup
          cmd.gsub!(/\/(.?)/){ "::#{$1.upcase}" }
          cmd.gsub!(/(?:_+|-+)([a-z])/){ $1.upcase }
          cmd.gsub!(/(\A|\s)([a-z])/){ $1 + $2.upcase }
          cmd
        end
      end

      module InstanceMethods
        include CommonMethods

        def commands
          self.class.commands
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