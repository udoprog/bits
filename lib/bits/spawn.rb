require 'bits/logging'

module Bits
  ENOENT = 0x7f
  PIPE = 0x01
  NULL = 0x02

  DEV_NULL = '/dev/null'

  class << self
    def handle_exit(pid, fd_cache)
      fd_cache.each do |key, fd|
        fd.close
      end

      Process.waitpid pid

      exitstatus = $?.exitstatus

      if exitstatus == ENOENT then
        raise Errno::ENOENT
      end

      if exitstatus != 0 then
        raise "Bad exit status: #{exitstatus}"
      end

      exitstatus
    end

    def setup_file(type, global, fd_cache)
      case type
        when PIPE then IO.pipe
        when NULL then (fd_cache[:null] ||= File.open(DEV_NULL, 'w'))
        else type
      end
    end

    def handle_child_file(type, global, fds)
      case type
      when PIPE then
        fds[0].close
        global.reopen fds[1]
      else
        global.reopen fds unless fds === global
      end
    end

    def handle_parent_file(type, fds)
      case type
      when PIPE then
        fds[1].close
        fds[0]
      else fds
      end
    end

    def spawn(args, params={})
      fd_cache = {}

      stdout = (params[:stdout] || $stdout)
      stderr = (params[:stderr] || $stderr)

      out = setup_file stdout, $stdout, fd_cache
      err = setup_file stderr, $stderr, fd_cache

      pid = fork do
        handle_child_file stdout, $stdout, out
        handle_child_file stderr, $stderr, err

        begin
          exec(*args)
        rescue Errno::ENOENT
          exit ENOENT
        rescue
          exit 1
        end
      end

      out = handle_parent_file stdout, out
      err = handle_parent_file stderr, err

      return handle_exit pid, fd_cache unless block_given?
      yield [out, err]
      handle_exit pid, fd_cache
    end
  end
end
