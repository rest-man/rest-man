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
