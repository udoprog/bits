module Bits
  # Used to provide a neat class based interface for reporting the last check
  # error.
  module ProviderReporting
    module ClassMethods
      def check_errors
        @check_errors ||= []
      end

      def last_check_error
        check_errors[-1]
      end

      def check_error(text)
        check_errors << text
        log.debug("Error on check: #{text}")
      end
    end

    def self.included(mod)
      mod.extend ClassMethods
    end
  end
end
