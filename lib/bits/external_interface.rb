require 'bits/logging'

require 'rubygems'
require 'json'

module Bits
  module ExternalInterface
    class Interface
      include Bits::Logging

      attr_reader :id, :capabilities, :exitstatus

      def initialize(id, args, stdin, data_f, pid)
        @id = id
        @args = args
        @stdin = stdin
        @data_f = data_f
        @pid = pid
        @capabilities = []
        @exitstatus = nil
        @timeout = 2
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
        response_type, response = begin
          timeout @timeout do
            request :ping
          end
        rescue Timeout::Error
          log.debug "Timeout when pinging interface"
          nil
        rescue
          log.debug "problem while pinging interface '#{@id}': #{$!}"
          nil
        end

        if response_type.nil?
          return
        end

        unless response_type == :pong
          raise "Expected pong but got #{response_type}"
        end

        @capabilities = (response['capabilities'] || []).map(&:to_sym)
        return true
      end

      def request(request_type, command={})
        command[:__type__] = request_type

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
        reap_child
      end

      private

      def reap_child
        unless @exitstatus.nil?
          return
        end

        log.debug "Killing interface '#{id}' (#{info_s})"

        Process::kill "INT", @pid

        log.debug "Waiting for interface '#{id}' to shutdown"

        # don't hang since write might have reaped it already.
        Process.wait @pid

        @exitstatus = $?.exitstatus

        @stdin.close unless @stdin.closed?
        @data_f.close unless @data_f.closed?
      end

      def write(data)
        @stdin.puts data
        @stdin.flush
      rescue
        reap_child
        raise
      end

      # read or no-op if it has been closed.
      def read
        @data_f.gets
      rescue
        reap_child
        raise
      end

      def info_s
        "pid=#{@pid} stdin=#{@stdin.fileno} data_fd=#{@data_f.fileno}"
      end

      def to_s
        "<Interface '#{@id}' info:#{info_s}>"
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
          log.debug "Interface '#{id}' is available, but misses capabilities: #{missing_s}"
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

        # data file descriptor.
        data_r, data_w = IO.pipe
        stdin_r, stdin_w = IO.pipe

        pid = fork do
          stdin_w.close
          data_r.close

          # add an extra argument telling the child process which file
          # descriptor to use when writing data.
          command << data_w.fileno.to_s

          $stdin.reopen stdin_r

          begin
            exec(*command)
          rescue Errno::ENOENT
            stdin_r.close
            data_w.close
            exit ENOENT
          end

          exit 1
        end

        stdin_r.close
        data_w.close

        interface = Interface.new(id, command, stdin_w, data_r, pid)

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
