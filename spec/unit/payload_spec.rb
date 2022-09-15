# encoding: binary

require_relative '_lib'

describe RestMan::Payload, :include_helpers do
  context "Base Payload" do
    it "should reset stream after to_s" do
      payload = RestMan::Payload::Base.new('foobar')
      expect(payload.to_s).to eq 'foobar'
      expect(payload.to_s).to eq 'foobar'
    end
  end

  context "A regular Payload" do
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

  context "Payload generation" do
    it "should recognize standard urlencoded params" do
      expect(RestMan::Payload.generate({"foo" => 'bar'})).to be_kind_of(RestMan::Payload::UrlEncoded)
    end

    it "should recognize multipart params" do
      f = File.new(test_image_path)
      expect(RestMan::Payload.generate({"foo" => f})).to be_kind_of(RestMan::Payload::Multipart)
    end

    it "should be multipart if forced" do
      expect(RestMan::Payload.generate({"foo" => "bar", :multipart => true})).to be_kind_of(RestMan::Payload::Multipart)
    end

    it "should handle deeply nested multipart" do
      f = File.new(test_image_path)
      params = {foo: RestMan::ParamsArray.new({nested: f})}
      expect(RestMan::Payload.generate(params)).to be_kind_of(RestMan::Payload::Multipart)
    end


    it "should return data if no of the above" do
      expect(RestMan::Payload.generate("data")).to be_kind_of(RestMan::Payload::Base)
    end

    it "should recognize nested multipart payloads in hashes" do
      f = File.new(test_image_path)
      expect(RestMan::Payload.generate({"foo" => {"file" => f}})).to be_kind_of(RestMan::Payload::Multipart)
    end

    it "should recognize nested multipart payloads in arrays" do
      f = File.new(test_image_path)
      expect(RestMan::Payload.generate({"foo" => [f]})).to be_kind_of(RestMan::Payload::Multipart)
    end

    it "should recognize file payloads that can be streamed" do
      f = File.new(test_image_path)
      expect(RestMan::Payload.generate(f)).to be_kind_of(RestMan::Payload::Streamed)
    end

    it "should recognize other payloads that can be streamed" do
      expect(RestMan::Payload.generate(StringIO.new('foo'))).to be_kind_of(RestMan::Payload::Streamed)
    end

    # hashery gem introduces Hash#read convenience method. Existence of #read method used to determine of content is streameable :/
    it "shouldn't treat hashes as streameable" do
      expect(RestMan::Payload.generate({"foo" => 'bar'})).to be_kind_of(RestMan::Payload::UrlEncoded)
    end

    it "should recognize multipart payload wrapped in ParamsArray" do
      f = File.new(test_image_path)
      params = RestMan::ParamsArray.new([[:image, f]])
      expect(RestMan::Payload.generate(params)).to be_kind_of(RestMan::Payload::Multipart)
    end

    it "should handle non-multipart payload wrapped in ParamsArray" do
      params = RestMan::ParamsArray.new([[:arg, 'value1'], [:arg, 'value2']])
      expect(RestMan::Payload.generate(params)).to be_kind_of(RestMan::Payload::UrlEncoded)
    end

    it "should pass through Payload::Base and subclasses unchanged" do
      payloads = [
        RestMan::Payload::Base.new('foobar'),
        RestMan::Payload::UrlEncoded.new({:foo => 'bar'}),
        RestMan::Payload::Streamed.new(File.new(test_image_path)),
        RestMan::Payload::Multipart.new({myfile: File.new(test_image_path)}),
      ]

      payloads.each do |payload|
        expect(RestMan::Payload.generate(payload)).to equal(payload)
      end
    end
  end
end
