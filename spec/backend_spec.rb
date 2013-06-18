require 'bits/backend'

describe Bits::Backend do
  it "Backend should raise exception when fetch is not implemented" do
    atom = double
    backend = Class.new Bits::Backend
    b = backend.new
    expect{ b.fetch(atom) }.to raise_error
  end
end
