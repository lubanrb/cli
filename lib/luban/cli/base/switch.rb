module Luban
  module CLI
    class Switch < Option
      def default_str
        @default_str ||= build_default_str
      end

      protected

      def init_config
        super
        # Ensure value type to be boolean
        @config[:type] = :bool
        # Ensure single value instead of multiple
        @config[:multiple] = false
      end

      def build_default_str
        @config[:default] ? "--#{long_opt_name}" : ""
      end

      def build_long_option
        "--#{long_opt_name}"
      end
    end

    class NegatableSwitch < Switch
      def kind; @kind ||= "negatable switch"; end

      protected

      def build_default_str
        @config[:default] ? "--#{long_opt_name}" : "--no-#{long_opt_name}"
      end

      def build_long_option
        "--[no-]#{long_opt_name}"
      end
    end
  end
end
