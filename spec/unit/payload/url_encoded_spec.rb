# encoding: binary

require_relative '../_lib'

describe RestMan::Payload::UrlEncoded, :include_helpers do

  it "should use standard enctype as default content-type" do
    expect(RestMan::Payload::UrlEncoded.new({}).headers['Content-Type']).
      to eq 'application/x-www-form-urlencoded'
  end

  it "should form properly encoded params" do
    expect(RestMan::Payload::UrlEncoded.new({:foo => 'bar'}).to_s).
      to eq "foo=bar"
    expect(["foo=bar&baz=qux", "baz=qux&foo=bar"]).to include(
                                                      RestMan::Payload::UrlEncoded.new({:foo => 'bar', :baz => 'qux'}).to_s)
  end

  it "should escape parameters" do
    expect(RestMan::Payload::UrlEncoded.new({'foo + bar' => 'baz'}).to_s).
      to eq "foo+%2B+bar=baz"
  end

  it "should properly handle hashes as parameter" do
    expect(RestMan::Payload::UrlEncoded.new({:foo => {:bar => 'baz'}}).to_s).
      to eq "foo[bar]=baz"
    expect(RestMan::Payload::UrlEncoded.new({:foo => {:bar => {:baz => 'qux'}}}).to_s).
      to eq "foo[bar][baz]=qux"
  end

  it "should handle many attributes inside a hash" do
    parameters = RestMan::Payload::UrlEncoded.new({:foo => {:bar => 'baz', :baz => 'qux'}}).to_s
    expect(parameters).to eq 'foo[bar]=baz&foo[baz]=qux'
  end

  it "should handle attributes inside an array inside an hash" do
    parameters = RestMan::Payload::UrlEncoded.new({"foo" => [{"bar" => 'baz'}, {"bar" => 'qux'}]}).to_s
    expect(parameters).to eq 'foo[][bar]=baz&foo[][bar]=qux'
  end

  it "should handle arrays inside a hash inside a hash" do
    parameters = RestMan::Payload::UrlEncoded.new({"foo" => {'even' => [0, 2], 'odd' => [1, 3]}}).to_s
    expect(parameters).to eq 'foo[even][]=0&foo[even][]=2&foo[odd][]=1&foo[odd][]=3'
  end

  it "should form properly use symbols as parameters" do
    expect(RestMan::Payload::UrlEncoded.new({:foo => :bar}).to_s).
      to eq "foo=bar"
    expect(RestMan::Payload::UrlEncoded.new({:foo => {:bar => :baz}}).to_s).
      to eq "foo[bar]=baz"
  end

  it "should properly handle arrays as repeated parameters" do
    expect(RestMan::Payload::UrlEncoded.new({:foo => ['bar']}).to_s).
      to eq "foo[]=bar"
    expect(RestMan::Payload::UrlEncoded.new({:foo => ['bar', 'baz']}).to_s).
      to eq "foo[]=bar&foo[]=baz"
  end

  it 'should not close if stream already closed' do
    p = RestMan::Payload::UrlEncoded.new({'foo ' => 'bar'})
    3.times {p.close}
  end

end