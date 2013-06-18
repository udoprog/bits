require 'bits/repository'

describe Bits::Repository do
  it "checks dependencies" do
    providers = double "providers"
    backend = double "backend"
    package_proxy = double "package_proxy"
    package_proxy.stub(:dependencies => {})

    repo = Bits::Repository.new providers, backend
  end
end
