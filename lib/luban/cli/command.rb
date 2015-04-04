module Luban
  module CLI
    class Command < Base
      attr_reader :name
      attr_reader :parent

      def initialize(app, name, parent: nil, prefix: '__command_', &config_blk)
        @name = name
        @parent = parent
        super(app, name, prefix: prefix, &config_blk)
      end

      protected

      def command_chain
        return @command_chain unless @command_chain.nil?
        chain = [name]
        next_parent = parent
        while !next_parent.nil?
          chain.unshift next_parent.name
          next_parent = next_parent.parent
        end
        @command_chain = chain.join(' ')
      end

      def compose_banner
        "Usage: #{program_name} #{command_chain} #{compose_synopsis}"
      end
    end
  end
end