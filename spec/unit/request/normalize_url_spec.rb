require_relative '../_lib'

describe "RestMan::Request.normalize_url", :include_helpers do

  let(:request) { RestMan::Request.new(:method => :get, :url => 'http://some/resource') }

  it "adds http:// to the front of resources specified in the syntax example.com/resource" do
    expect(request.normalize_url('example.com/resource')).to eq 'http://example.com/resource'
  end

  it 'adds http:// to resources containing a colon' do
    expect(request.normalize_url('example.com:1234')).to eq 'http://example.com:1234'
  end

  it 'does not add http:// to the front of https resources' do
    expect(request.normalize_url('https://example.com/resource')).to eq 'https://example.com/resource'
  end

  it 'does not add http:// to the front of capital HTTP resources' do
    expect(request.normalize_url('HTTP://example.com/resource')).to eq 'HTTP://example.com/resource'
  end

  it 'does not add http:// to the front of capital HTTPS resources' do
    expect(request.normalize_url('HTTPS://example.com/resource')).to eq 'HTTPS://example.com/resource'
  end

  it 'raises with invalid URI' do
    expect {
      RestMan::Request.new(method: :get, url: 'http://a@b:c')
    }.to raise_error(URI::InvalidURIError)
    expect {
      RestMan::Request.new(method: :get, url: 'http://::')
    }.to raise_error(URI::InvalidURIError)
  end

end
