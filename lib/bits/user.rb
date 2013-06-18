module Bits
  class User
    def superuser?
      raise "not implemented: superuser?"
    end
  end

  class PosixUser < User
    def superuser?
      Process.uid == 0
    end
  end

  def self.setup_user
    if RUBY_PLATFORM.include? 'darwin'
      kind = PosixUser
    elsif RUBY_PLATFORM.include? 'linux'
      kind = PosixUser
    elsif RUBY_PLATFORM.include? 'win32'
      kind = Win32User
    else
      raise "Unsupported platform: #{RUBY_PLATFORM}"
    end

    kind.new
  end
end
