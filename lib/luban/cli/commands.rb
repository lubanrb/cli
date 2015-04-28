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

        def use_commands(mod_name)
          mod_class = Kernel.const_get(camelcase(mod_name.to_s))
          mod_class.constants.map { |c| mod_class.const_get(c) }.each do |c|
            command(snakecase(c.name.sub(/Command$/, ''))) if c < Luban::CLI::Command
          end
        end

        protected

        def camelcase(str)
          str = str.to_s.dup
          str.gsub!(/\:(.?)/){ "::#{$1.upcase}" }
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

      module ClassMethods
        include CommonMethods

        def commands
          @commands ||= {}
        end

        def command_class(cmd)
          "#{camelcase(cmd)}Command"
        end

        def command(app = self, cmd, **opts, &blk)
          cmd = cmd.to_sym
          cmd_class = command_class(cmd)
          klass = if self.const_defined?(command_class(cmd))
                    self.const_get(command_class(cmd))
                  else
                    self.const_set(command_class(cmd), Class.new(Command))
                  end
          commands[cmd] = klass.new(app, cmd, **opts, &blk)
        end

        def undef_command(cmd)
          undef_method(commands.delete(cmd).action_method)
        end
      end

      module InstanceMethods
        include CommonMethods

        def commands
          self.class.commands
        end

        def command(cmd, **opts, &blk)
          cmd = cmd.to_sym
          if self.is_a?(Command)
            opts[:command_chain] = self.command_chain.clone.push(cmd)
            self.class.command(self.app, cmd, **opts, &blk)
          else
            self.class.command(cmd, **opts, &blk)
          end
        end

        def undef_command(cmd)
          self.class.undef_command(cmd)
        end
      end
    end
  end
end