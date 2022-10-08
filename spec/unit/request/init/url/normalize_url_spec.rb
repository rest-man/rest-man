require_relative "../../../_lib"

RSpec.describe RestMan::Request::Init::Url::NormalizeUrl do

  it "adds http:// to the front of resources specified in the syntax example.com/resource" do
    expect(RestMan::Request::Init::Url::NormalizeUrl.call('example.com/resource')).to eq 'http://example.com/resource'
  end

  it 'adds http:// to resources containing a colon' do
    expect(RestMan::Request::Init::Url::NormalizeUrl.call('example.com:1234')).to eq 'http://example.com:1234'
  end

  it 'does not add http:// to the front of https resources' do
    expect(RestMan::Request::Init::Url::NormalizeUrl.call('https://example.com/resource')).to eq 'https://example.com/resource'
  end

  it 'does not add http:// to the front of capital HTTP resources' do
    expect(RestMan::Request::Init::Url::NormalizeUrl.call('HTTP://example.com/resource')).to eq 'HTTP://example.com/resource'
  end

  it 'does not add http:// to the front of capital HTTPS resources' do
    expect(RestMan::Request::Init::Url::NormalizeUrl.call('HTTPS://example.com/resource')).to eq 'HTTPS://example.com/resource'
  end

end
