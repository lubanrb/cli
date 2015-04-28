module Luban
  module CLI
    class Command < Base
      attr_reader :name
      attr_reader :command_chain

      def initialize(app, name, command_chain: [name], **opts, &config_blk)
        @name = name
        @command_chain = command_chain
        super(app, name, **opts, &config_blk)
      end

      def default_prefix; '__command_'; end

      def action_method
        @action_method ||= "#{@prefix}#{command_chain.map(&:to_s).join('_').gsub(':', '_')}"
      end

      protected

      def compose_banner
        "Usage: #{program_name} #{command_chain.map(&:to_s).join(' ')} #{compose_synopsis}"
      end
    end
  end
end