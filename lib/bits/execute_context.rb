module Bits
  class ExecuteContext
    SUDO = 'sudo'

    def initialize(user)
      @user = user
    end

    def spawn(args, params={})
      superuser = params[:superuser] || false

      if superuser and not @user.superuser?
        Bits.spawn [SUDO] + args, params
      else
        Bits.spawn args, params
      end
    end

    # Run a command and return a boolean indicating weither exitcode is 0
    def run(args, params={})
      params[:ignore_exitcode] = true
      spawn(args, params) == 0
    end
  end
end
