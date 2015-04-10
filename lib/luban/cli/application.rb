require 'pathname'

module Luban
  module CLI
    class Application < Base
      attr_reader :rc

      def initialize(action_name = :run, **opts, &config_blk)
        super(self, action_name, **opts, &config_blk)
        @rc = init_rc
        validate
      end

      def rc_file
        @rc_file ||= ".#{program_name}rc"
      end

      def rc_path
        @rc_path ||= Pathname.new(ENV['HOME']).join(rc_file)
      end

      def rc_file_exists?
        File.exists?(rc_path)
      end

      def default_rc
        @default_rc ||= {}
      end

      protected

      def validate; end

      def init_rc
        if rc_file_exists?
          default_rc.merge(load_rc_file)
        else
          default_rc.clone
        end
      end

      def load_rc_file
        require 'yaml'
        YAML.load_file(rc_path)
      end
    end
  end
end