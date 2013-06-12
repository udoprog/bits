require 'bits/spawn'
require 'json'

module Bits
  # Helper functions for writing providers which mainly interacts with external
  # commands.
  module CommandProvider
    module ClassMethods
      def check_command(command, name)
        begin
          exit_code = Bits.spawn command, :stdout => NULL
        rescue Errno::ENOENT
          log.debug "#{name} command not available"
          return false
        end

        if exit_code != 0 then
          log.debug "#{name} command could not be invoked"
          return false
        end

        log.debug "#{name} command available"
        true
      end

      def run(args)
        Bits.spawn args == 0
      end

      def external_json(*args)
        data = nil

        exit_status = Bits.spawn args, :stdout => PIPE do |o, e|
          data = o.read
        end

        return nil if exit_status != 0

        raise "Could not get output data" if data.nil?

        blob = JSON.load data
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
