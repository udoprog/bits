require 'bits/logging'

require 'rubygems'
require 'json'

module Bits
  module ExternalInterface
    class Interface
      include Bits::Logging

      attr_reader :id, :capabilities, :exitstatus

      def initialize(id, args, stdin, stdout, pid)
        @id = id
        @args = args
        @stdin = stdin
        @stdout = stdout
        @pid = pid
        @capabilities = []
        @exitstatus = nil
      end

      # end the child process by closing stdin.
      def end
        @stdin.close
        reap_child
      end

      def info(atom)
        type, response = request :info, :atom => atom
      end

      def ping
        begin
          type, response = request :ping
        rescue
          log.debug "problem while pinging interface '#{@id}': #{$!}"
          return nil
        end

        raise "Expected pong but got #{type}" unless type == :pong
        @capabilities = (response['capabilities'] || []).map(&:to_sym)
        return true
      end

      def request(type, command={})
        command[:__type__] = type

        write JSON.dump(command)
        data = read

        raise "empty response" if data.nil?

        response = JSON.load(data)

        response_type = response['__type__'].to_sym

        if response_type == :error
          error_text = response['text']
          raise "Error in interface: #{error_text}"
        end

        [response_type, response]
      end

      def close
        return if @stdin.nil? and @stdout.nil?
        reap_child
      end

      private

      def reap_child
        log.debug "Reaping interface: #{id}"
        return if @exitstatus.nil?
        log.debug "stdin=#{@stdin.inspect} stdout=#{@stdout.inspect}"

        @stdin.close
        @stdout.close

        log.debug "Waiting for interface to exit: #{id} [#{$?.inspect}]"
        # don't hang since write might have reaped it already.

        Process.wait @pid
        @exitstatus = $?.exitstatus

        log.debug "done: #{id} exitstatus=#{@exitstatus}"
      end

      def write(data)
        return if @stdin.nil?
        @stdin.puts data
        @stdin.flush
      rescue
        reap_child
        raise
      end

      # read or no-op if it has been closed.
      def read
        return if @stdout.nil?
        @stdout.gets
      rescue
        reap_child
        raise
      end
    end

    module ClassMethods
      # access global interface cache for class methods.
      def interfaces
        ExternalInterface.interfaces
      end

      # Spawn an interface that is shared between all users.
      def setup_interface(id, params = {})
        capabilities = params[:capabilities] || []

        interface = spawn_interface id

        if interface.nil?
          log.debug "Interface '#{id}' not available"
          return false
        end

        missing_capabilities = capabilities - interface.capabilities

        unless missing_capabilities.empty?
          missing_s = missing_capabilities.join ', '
          log.debug "Interface '#{id}' is available, but is missing capabilities: #{missing_s}"
          return false
        end

        has_s = capabilities.join ', '
        log.debug "Interface '#{id}' is available with capabilities: #{has_s}"
        return true
      end

      private

      def spawn_interface(id)
        unless interfaces[id].nil?
          return interfaces[id]
        end

        libexec_path = path_to_libexec "bits-#{id}"

        command = [libexec_path]

        stdout_r, stdout_w = IO.pipe
        stdin_r, stdin_w = IO.pipe

        pid = fork do
          stdin_w.close
          stdout_r.close

          $stdin.reopen stdin_r
          $stdout.reopen stdout_w

          begin
            exec(*command)
          rescue Errno::ENOENT
            $stdout.close
            $stdin.close
            exit ENOENT
          end

          exit 1
        end

        stdin_r.close
        stdout_w.close

        interface = Interface.new(id, command, stdin_w, stdout_r, pid)

        if not interface.ping
          interface.close
          return nil
        end

        interfaces[id] = interface
      end

      def path_to_libexec(name)
        File.join File.dirname(File.expand_path(__FILE__)), File.join('..', 'libexec', name)
      end
    end

    # global cache for interfaces.
    def self.interfaces
      @interfaces ||= {}
    end

    # access global interface cache for instances.
    def interfaces
      self.class.interfaces
    end

    # close all global interfaces
    def self.close_interfaces
      interfaces.each do |id, interface|
        interface.close
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
