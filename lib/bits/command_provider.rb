require 'bits/spawn'
require 'json'

module Bits
  # Helper functions for writing providers which mainly interacts with external
  # commands.
  module CommandProvider
    module ClassMethods
      def check_command(command, name)
        exit_code = File.open '/dev/null', 'w' do |dev_null|
          begin
            Bits.spawn command, :stdout => dev_null, :stderr => dev_null
          rescue Errno::ENOENT
            log.debug "#{name} command not available"
            return false
          end
        end

        if exit_code != 0 then
          log.debug "#{name} command could not be invoked"
          return false
        end

        log.debug "#{name} command available"
        true
      end
    end

    def check_command(*args)
      self.class.check_command(*args)
    end

    def run(*args)
      self.class.run(*args)
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
