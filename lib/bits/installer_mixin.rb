require 'highline'

module Bits::InstallerMixin
  def setup_installer_opts opts
    opts.on('--[no-]compiled', "Insist on installing an already compiled variant or not") do |v|
      ns[:compiled] = v
    end

    opts.on('--force', "Insist on installing even if packages already installed") do |v|
      ns[:force] = v
    end
  end

  def install_package package, force=false
    atom = package.atom

    if package.installed? and not force
      log.info "Already installed '#{atom}' using provider(s): #{package.providers_s}"
      return
    end

    matching = package.matching_ppps

    raise "No matching PPP could be found" if matching.empty?

    ppp = pick_one atom, matching

    install_ppp atom, ppp
  end

  # Resolve a hash of dependencies with a criteria to packages.
  # Returns [<packages>, error]
  def resolve_packages(depends, criteria)
    repository = ns[:repository]

    raise "No repository in namespace" if repository.nil?

    packages = Array.new
    missing = Array.new

    unless depends.kind_of? Array
      raise ":depends should be a List"
    end

    depends.each do |spec|
      unless spec.kind_of? Hash
        raise "dependency should be of type Hash"
      end

      atom = spec[:atom]

      if atom.nil?
        raise "dependency must specify :atom"
      end

      crit = Hash.new
      crit = criteria[:compiled] unless criteria[:compiled].nil?
      crit = spec[:compiled] unless spec[:compiled].nil?

      begin
        packages << repository.find_package(atom, crit)
      rescue Bits::MissingBit
        missing << atom
      end
    end

    unless missing.empty?
      raise Bits::MissingDependencies.new missing
    end

    packages
  end

  private

  def pick_one(atom, matching)
    return matching[0] if matching.size == 1

    hl = HighLine.new $stdin

    hl.choose do |menu|
      menu.prompt = "Which provider would you like to install '#{atom}' with?"
      matching.each do |match|
        menu.choice(match.provider.provider_id) { match }
      end
    end
  end

  def install_ppp(atom, ppp)
    provider = ppp.provider
    package = ppp.package

    log.info "Installing '#{atom}' using provider: #{provider.provider_id}"
    provider.install package
  end
end
