require 'bits/package_proxy'

describe Bits::PackageProxy do
  it "should match criteria" do
    ppps = double
    criteria = {:foo => true}
    p = Bits::PackageProxy.new ppps, criteria
    p.matches_criteria?({:foo => false})
  end
end
