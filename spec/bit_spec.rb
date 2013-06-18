require 'bits/bit'

describe Bits::Bit do
  it "should have provider ids equal to keys" do
    atom = double
    keys = []
    provides = double('provides', :keys => keys)
    expect(keys).to eq(keys)
    dependencies = double

    bit = Bits::Bit.new atom, provides, dependencies

    expect(bit.provider_ids).to eq(keys)
  end
end
