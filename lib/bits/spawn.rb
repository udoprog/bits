module Bits
  ENOENT = 0x7f
  PIPE = 0x01

  def self.handle_exit(pid)
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

  def self.setup_file(type, global)
    case type
      when PIPE then IO.pipe
      else type
    end
  end

  def self.handle_child_file(type, global, fds)
    case type
    when PIPE then
      fds[0].close
      global.reopen fds[1]
    else
      global.reopen fds unless fds === global
    end
  end

  def self.handle_parent_file(type, fds)
    case type
    when PIPE then
      fds[1].close
      fds[0]
    else fds
    end
  end

  def self.spawn(args, params={})
    stdout = (params[:stdout] || $stdout)
    stderr = (params[:stderr] || $stderr)

    out = setup_file stdout, $stdout
    err = setup_file stderr, $stderr

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

    return handle_exit pid unless block_given?
    yield [out, err]
    handle_exit pid
  end
end
