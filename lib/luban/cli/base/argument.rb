module Luban
  module CLI
    class Argument
      class InvalidArgumentValue < Error; end
      class TypeCastingFailed < Error; end
      
      attr_reader :name
      attr_reader :display_name
      attr_reader :description
      attr_accessor :value

      def initialize(name, desc, **config, &blk)
        @name = name
        @display_name = name.to_s.upcase
        @description = desc.to_s
        @handler = block_given? ? blk : ->(v) { v }
        @config = config
        init_config
        verify_config
        reset
      end

      def kind
        @kind ||= self.class.name.split('::').last.downcase
      end

      def reset
        @value = set_default_value
      end

      def value=(v)
        @value = process(v).tap { |v| validate(v) }
      end

      def default_type; :string; end
      def default_imperative; true; end

      def [](key); @config[key]; end

      def required?; @config[:required]; end
      def optional?; !@config[:required]; end
      def has_default?; !@config[:default].nil?; end
      def multiple?; @config[:multiple]; end

      def validate(value = @value)
        unless valid?(value)
          raise InvalidArgumentValue, "Invalid value of #{kind} #{display_name}: #{value.inspect}"
        end
      end

      def valid?(value = @value)
        (multiple? ? value : [value]).all? do |v| 
          !missing?(v) and match?(v) and within?(v) and assured?(v)
        end
      end

      def missing?(value = @value)
        required? and value.nil?
      end

      def match?(value = @value)
        @config[:match].nil? ? true : !!@config[:match].match(value)
      end

      def within?(value = @value)
        @config[:within].nil? ? true : @config[:within].include?(value)
      end

      def assured?(value = @value)
        @config[:assure].nil? ? true : !!@config[:assure].call(value)
      end

      protected

      def init_config
        @config[:type] ||= default_type
        @config[:required] = default_imperative if @config[:required].nil?
        @config[:required] = !!@config[:required]
        @config[:multiple] = !!@config[:multiple]
      end

      def verify_config
        verify_config_type if @config.has_key?(:type)
        verify_config_default_value if @config.has_key?(:default)
        verify_config_match if @config.has_key?(:match)
        verify_config_within if @config.has_key?(:within)
        verify_config_assurance if @config.has_key?(:assure)
      end

      def verify_config_type
        @config[:type] = normalize_type(@config[:type])
        unless respond_to?(cast_method(@config[:type]), true)
          raise ArgumentError, "NOT castable type for #{kind} #{display_name}: #{@config[:type]}"
        end
      end

      def normalize_type(type); type.to_s.downcase.to_sym; end

      def verify_config_default_value
        err_msg = nil
        type = @config[:type]
        default = @config[:default]
        unless type.nil?
          if multiple?
            unless default.is_a?(Array) and
                   default.all? { |v| send("#{type}?", v) }
              err_msg = "must be an array of #{type} instances"
            end
          else
            unless send("#{type}?", default)
              err_msg = "must be an instance of #{type}"
            end
          end
        end
        unless err_msg.nil?
          raise ArgumentError, "Default value for #{kind} #{display_name} #{err_msg}"
        end
        unless valid?(default)
          raise ArgumentError, "Invalid default value for #{kind} #{display_name}: #{default.inspect}"
        end
      end

      def verify_config_match
        unless @config[:match].respond_to?(:match)
          raise ArgumentError, "Matching pattern of #{kind} #{display_name} must respond to #match."
        end
      end

      def verify_config_within
        unless @config[:within].respond_to?(:include?)
          raise ArgumentError, "Possible values of #{kind} #{display_name} must respond to #include?."
        end
      end

      def verify_config_assurance
        unless @config[:assure].respond_to?(:call)
          raise ArgumentError, "Assurance of #{kind} #{display_name} must be callable."
        end
      end

      def set_default_value(value = nil)
        if !@config[:default].nil? and value.nil?
          @config[:default]
        else
          value
        end
      end

      def process(value)
        post_process(@handler.call(pre_process(value)))
      end

      def pre_process(value)
        cast_type(set_default_value(value))
      end

      def post_process(value); value; end

      def cast_type(value)
        unless value.nil?
          if multiple?
            value.map! { |v| cast_value(v) }
          else
            value = cast_value(value)
          end
        end
        value
      end

      def cast_value(value)
        if send("#{@config[:type]}?", value)
          value
        else
          method(cast_method(@config[:type])).call(value)
        end
      rescue StandardError => e
        raise TypeCastingFailed, "Type casting to #{@config[:type]} for #{kind} #{display_name} failed: #{e.class.name} - #{e.message}"
      end

      def cast_method(type); "cast_#{type}"; end

      def cast_string(value); String(value); end
      def cast_integer(value); Integer(value); end
      def cast_float(value); Float(value); end
      def cast_symbol(value); value.to_sym; end
      def cast_time(value); Time.parse(value); end
      def cast_date(value); Date.parse(value); end
      def cast_datetime(value); DateTime.parse(value); end
      BoolValues = {"true" => true, "false" => false, "yes" => true, "no" => false }
      def cast_bool(value); !!BoolValues[value.to_s.downcase]; end

      def string?(value); value.is_a?(String); end
      def integer?(value); value.is_a?(Integer); end
      def float?(value); value.is_a?(Float); end
      def symbol?(value); value.is_a?(Symbol); end
      def time?(value); value.is_a?(Time); end
      def date?(value); value.is_a?(Date); end
      def datetime?(value); value.is_a?(DateTime); end
      def bool?(value); value.is_a?(TrueClass) or value.is_a?(FalseClass); end
    end
  end
end
