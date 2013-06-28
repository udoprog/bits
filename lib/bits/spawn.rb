require 'bits/logging'

module Bits
  class << self
    def handle_exit(pid, ignore_exitcode)
      Process.waitpid pid

      exitstatus = $?.exitstatus

      if not ignore_exitcode and exitstatus != 0 then
        raise "Bad exit status: #{exitstatus}"
      end

      exitstatus
    end

    def spawn_check_errno(errno_r)
      while true
        begin
          errno_data = errno_r.read(4)
        rescue Errno::EAGAIN, Errno::EINTR
          next
        rescue SystemCallError
          break
        end

        if errno_data
          errno = errno_data.unpack('i')[0]
          raise SystemCallError.new('Failed to execute command', errno)
        end

        break
      end
    end

    def spawn_exec(command, errno_w)
      begin
        exec(*command)
      rescue SystemCallError => e
        errno_w.write [e.errno].pack('i')
      end

      exit 1
    end

    def spawn(command, params={})
      stdout = params[:stdout]
      stderr = params[:stderr]
      ignore_exitcode = params[:ignore_exitcode] || false

      errno_r, errno_w = IO.pipe

      pid = fork do
        errno_r.close
        errno_w.close_on_exec = true

        $stdout.reopen stdout unless stdout.nil?
        $stderr.reopen stderr unless stderr.nil?

        spawn_exec command, errno_w
      end

      errno_w.close

      spawn_check_errno errno_r

      handle_exit pid, ignore_exitcode
    end
  end
end
