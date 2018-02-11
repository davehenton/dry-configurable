require 'dry-struct'
# A collection of micro-libraries, each intended to encapsulate
# a common task in Ruby
module Dry
  # A simple configuration mixin
  #
  # @example
  #
  #   class App
  #     extend Dry::ConfigurableV2
  #
  #     setting :database_url, Types::String.constrained(filled: true)
  #     setting :path, Types::Strict::String do |value|
  #       Pathname(value)
  #     end
  #   end
  #
  #   App.configure do
  #     config :database_url, 'jdbc:sqlite:memory'
  #   end
  #
  #   App.config.database_url
  #     # => "jdbc:sqlite:memory'"
  #
  # @api public
  module ConfigurableV2
    class NotConfigured < StandardError; end

    class ProxySettings
      def initialize(settings, processors, &block)
        @settings = settings
        @processors = processors
        @schema = {}
        instance_eval(&block)
      end

      def config(key, value)
        if @settings.attribute?(key)
          @schema[key] = @processors.key?(key) ? @processors[key].call(value) : value
        end
      end

      def schema
        @schema
      end
    end

    def self.extended(base)
      base.class_eval do
        @settings = Class.new(Dry::Struct)
        @processors = ::Concurrent::Hash.new
      end
    end

    def setting(name, type, &block)
      @settings.attribute(name, type)
      @processors[name] = block if block
    end

    def configure(&block)
      settings_values = ProxySettings.new(@settings, @processors, &block).schema
      @config = @settings.new(settings_values)
      self
    end

    def config
      if defined?(@config)
        @config
      else
        @settings.new
      end
    rescue Dry::Struct::Error => e
      raise NotConfigured,
        "You need to use #configure method to setup values for your configuration, there are some values missing\n" +
        "#{e.message}"
    end
  end
end
