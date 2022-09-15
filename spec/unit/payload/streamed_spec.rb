# encoding: binary

require_relative '../_lib'

describe RestMan::Payload::Streamed, :include_helpers do

  it "should properly determine the size of file payloads" do
    f = File.new(test_image_path)
    payload = RestMan::Payload.generate(f)
    expect(payload.size).to eq 72_463
    expect(payload.length).to eq 72_463
  end

  it "should properly determine the size of other kinds of streaming payloads" do
    s = StringIO.new 'foo'
    payload = RestMan::Payload.generate(s)
    expect(payload.size).to eq 3
    expect(payload.length).to eq 3

    begin
      f = Tempfile.new "rest-man"
      f.write 'foo bar'

      payload = RestMan::Payload.generate(f)
      expect(payload.size).to eq 7
      expect(payload.length).to eq 7
    ensure
      f.close
    end
  end

  it "should have a closed? method" do
    f = File.new(test_image_path)
    payload = RestMan::Payload.generate(f)
    expect(payload.closed?).to be_falsey
    payload.close
    expect(payload.closed?).to be_truthy
  end

end
