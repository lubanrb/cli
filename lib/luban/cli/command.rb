module Luban
  module CLI
    class Command < Base
      attr_reader :name

      def initialize(app_class, name, &config_blk)
        super
        @name = name
      end

      protected

      def compose_banner
        "Usage: #{program_name} #{name} #{compose_synopsis}"
      end
    end
  end
end