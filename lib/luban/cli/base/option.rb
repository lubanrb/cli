module Luban
  module CLI
    class Option < Argument
      def specs
        specs = [ description ]
        specs << build_long_option
        specs << build_short_option if @config.has_key?(:short)
        specs << Array if multiple?
        specs
      end

      def default_imperative; false; end

      def default_str
        @default_str ||= has_default? ? build_default_str : ''
      end

      protected

      def build_default_str
        "--#{long_opt_name} #{default_value_str.inspect}"
      end

      def build_long_option
        "--#{long_opt_name} #{@display_name}"
      end

      def build_short_option
        "-#{@config[:short]}"
      end

      def long_opt_name
        (@config[:long] || @name).to_s.gsub('_', '-')
      end

      def default_value_str
        [*@config[:default]].map(&:to_s).join(",")
      end
    end

    class NullableOption < Option
      def kind; @kind ||= "nullable option"; end

      def value=(val)
        super
        @value = true if @value.nil?
        @value
      end

      protected

      def build_long_option
        "--#{long_opt_name} [#{@display_name}]"
      end
    end
  end
end
