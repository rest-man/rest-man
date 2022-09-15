# encoding: binary

require_relative '../_lib'

describe RestMan::Payload::Multipart, :include_helpers do

  it "should use standard enctype as default content-type" do
    m = RestMan::Payload::Multipart.new({})
    allow(m).to receive(:boundary).and_return(123)
    expect(m.headers['Content-Type']).to eq 'multipart/form-data; boundary=123'
  end

  it 'should not error on close if stream already closed' do
    m = RestMan::Payload::Multipart.new(:file => File.new(test_image_path))
    3.times {m.close}
  end

  it "should form properly separated multipart data" do
    m = RestMan::Payload::Multipart.new([[:bar, "baz"], [:foo, "bar"]])
    expect(m.to_s).to eq <<~EOS
      --#{m.boundary}\r
      Content-Disposition: form-data; name="bar"\r
      \r
      baz\r
      --#{m.boundary}\r
      Content-Disposition: form-data; name="foo"\r
      \r
      bar\r
      --#{m.boundary}--\r
      EOS
  end

  it "should not escape parameters names" do
    m = RestMan::Payload::Multipart.new([["bar ", "baz"]])
    expect(m.to_s).to eq <<~EOS
      --#{m.boundary}\r
      Content-Disposition: form-data; name="bar "\r
      \r
      baz\r
      --#{m.boundary}--\r
      EOS
  end

  it "should form properly separated multipart data" do
    f = File.new(test_image_path)
    m = RestMan::Payload::Multipart.new({:foo => f})
    expect(m.to_s).to eq <<~EOS
      --#{m.boundary}\r
      Content-Disposition: form-data; name="foo"; filename="ISS.jpg"\r
      Content-Type: image/jpeg\r
      \r
      #{File.open(f.path, 'rb'){|bin| bin.read}}\r
      --#{m.boundary}--\r
      EOS
  end

  it "should ignore the name attribute when it's not set" do
    f = File.new(test_image_path)
    m = RestMan::Payload::Multipart.new({nil => f})
    expect(m.to_s).to eq <<~EOS
      --#{m.boundary}\r
      Content-Disposition: form-data; filename="ISS.jpg"\r
      Content-Type: image/jpeg\r
      \r
      #{File.open(f.path, 'rb'){|bin| bin.read}}\r
      --#{m.boundary}--\r
      EOS
  end

  it "should detect optional (original) content type and filename" do
    f = File.new(test_image_path)
    expect(MIME::Types).to receive(:type_for).with(f.path).and_return("")
    expect(f).to receive(:original_filename).and_return('foo.txt')
    m = RestMan::Payload::Multipart.new({:foo => f})
    expect(m.to_s).to eq <<~EOS
      --#{m.boundary}\r
      Content-Disposition: form-data; name="foo"; filename="foo.txt"\r
      Content-Type: text/plain\r
      \r
      #{File.open(f.path, 'rb'){|bin| bin.read}}\r
      --#{m.boundary}--\r
      EOS
  end

  it "should handle hash in hash parameters" do
    m = RestMan::Payload::Multipart.new({:bar => {:baz => "foo"}})
    expect(m.to_s).to eq <<~EOS
      --#{m.boundary}\r
      Content-Disposition: form-data; name="bar[baz]"\r
      \r
      foo\r
      --#{m.boundary}--\r
      EOS

    f = File.new(test_image_path)
    f.instance_eval "def content_type; 'text/plain'; end"
    f.instance_eval "def original_filename; 'foo.txt'; end"
    m = RestMan::Payload::Multipart.new({:foo => {:bar => f}})
    expect(m.to_s).to eq <<~EOS
      --#{m.boundary}\r
      Content-Disposition: form-data; name="foo[bar]"; filename="foo.txt"\r
      Content-Type: text/plain\r
      \r
      #{File.open(f.path, 'rb'){|bin| bin.read}}\r
      --#{m.boundary}--\r
      EOS
  end

  it 'should correctly format hex boundary' do
    allow(SecureRandom).to receive(:base64).with(12).and_return('TGs89+ttw/xna6TV')
    f = File.new(test_image_path)
    m = RestMan::Payload::Multipart.new({:foo => f})
    expect(m.boundary).to eq('-' * 4 + 'RubyFormBoundary' + 'TGs89AttwBxna6TV')
  end

end
