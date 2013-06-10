require 'log4r'

module Bits
  module Logging
    module ClassMethods
      def setup_logging(name)
        @logging_name = name
      end

      def log
        @logging_logger ||= Log4r::Logger.new(@logging_name)
      end
    end

    def log
      self.class.log
    end

    def self.included(mod)
      mod.extend ClassMethods
      mod.setup_logging mod.to_s
    end
  end
end
