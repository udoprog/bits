module Bits
  class ExecuteContext
    SUDO = 'sudo'

    def initialize(user)
      @user = user
    end

    def spawn(args, params={})
      root = params[:root] || false

      if root and not @user.superuser?
        Bits.spawn [SUDO] + args, params
      else
        Bits.spawn args, params
      end
    end

    def run(args, params={})
      params[:ignore_exitcode] = true
      spawn(args, params) == 0
    end
  end
end
