require 'bits/logging'
require 'bits/spawn'
require 'bits/exceptions'

require 'rubygems'
require 'json'
require 'fcntl'

module Bits
  EXTERNAL_EXECUTABLES = {
    :python => 'python',
    :ruby => 'ruby',
    :node => 'node',
  }

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
        response_data = begin
          timeout @timeout do
            request :ping
          end
        rescue Timeout::Error
          log.warn "Timeout when pinging interface"
          nil
        end

        if response_data.nil?
          return false
        end

        response_type, content = response_data

        unless response_type == :pong
          raise "Expected pong but got #{response_type}"
        end

        @capabilities = (content['capabilities'] || []).map(&:to_sym)
        return true
      end

      def request(request_type, command={})
        command[:__type__] = request_type

        write JSON.dump(command)
        data = read

        if data.nil?
          raise InterfaceException.new 'Empty response'
        end

        response = JSON.load(data)

        response_type = response['__type__'].to_sym

        if response_type == :error
          error_text = response['text']
          raise InterfaceException.new "Error in interface: #{error_text}"
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

      def spawn_libexec_path(name)
        dir = File.dirname(File.expand_path(__FILE__))
        path = File.join dir, '..', 'libexec', name
        File.expand_path path
      end

      # Read and optionally raise an exception if the file descriptor
      # reports error.
      def spawn_read_error(errno_r)
        while true
          begin
            errno_data = errno_r.read(4)
          rescue SystemCallError => e
            if e.errno != Errno::EAGAIN and e.errno != Errno::EINTR
              break
            end

            next
          end

          if errno_data
            errno = errno_data.unpack 'i'
            raise SpawnException.new('Unable to execute command', errno)
          end

          break
        end
      end

      def spawn_interface(id)
        unless interfaces[id].nil?
          return interfaces[id]
        end

        executable = EXTERNAL_EXECUTABLES[id]

        if executable.nil?
          raise "No executable defined for provider '#{id}'"
        end

        libexec_path = spawn_libexec_path "bits-#{id}"

        unless File.file? libexec_path
          raise "No such file: #{libexec_path}"
        end

        command = [executable, libexec_path]

        # Data file descriptor.
        data_r, data_w = IO.pipe
        # Stdin
        stdin_r, stdin_w = IO.pipe
        # Errno reporting
        errno_r, errno_w = IO.pipe

        pid = fork do
          [errno_r, stdin_w, data_r].each(&:close)

          $stdin.reopen stdin_r

          errno_w.close_on_exec = true

          # add an extra argument telling the child process which file
          # descriptor to use when writing data.
          command << data_w.fileno.to_s

          Bits::spawn_exec command, errno_w
        end

        [errno_w, stdin_r, data_w].each(&:close)

        begin
          Bits::spawn_check_errno errno_r
        rescue Errno::ENOENT
          log.debug "Unable to execute command '#{executable}' for provider '#{id}'"
          return nil
        end

        interface = Interface.new(id, command, stdin_w, data_r, pid)

        if not interface.ping
          interface.close
          return nil
        end

        interfaces[id] = interface
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
