require_relative '_lib'

describe RestMan::Exception do

  it "contains exceptions in RestMan" do
    expect(RestMan::Unauthorized.new).to be_a_kind_of(RestMan::Exception)
    expect(RestMan::ServerBrokeConnection.new).to be_a_kind_of(RestMan::Exception)
  end

  describe '#message' do
    it "returns a 'message' equal to the class name if the message is not set, because 'message' should not be nil" do
      e = RestMan::Exception.new
      expect(e.message).to eq "RestMan::Exception"
    end

    it "returns the 'message' that was set" do
      e = RestMan::Exception.new
      message = "An explicitly set message"
      e.message = message
      expect(e.message).to eq message
    end

    it "sets the exception message to ErrorMessage" do
      expect(RestMan::ResourceNotFound.new.message).to eq 'Not Found'
    end
  end

  describe "#http_code" do
    it 'return the initial_response_code' do
      e = RestMan::Exception.new(nil, 111)
      expect(e.http_code).to eq(111)
    end

    it 'return from response.code' do
      e = RestMan::Exception.new(double("response", code: '111'))
      expect(e.http_code).to eq(111)
    end
  end

  describe "#http_headers" do
    it 'return from response.headers' do
      e = RestMan::Exception.new(double("response", headers: 'headers'))
      expect(e.http_headers).to eq("headers")
    end

    it 'return nil when response is nil' do
      e = RestMan::Exception.new
      expect(e.http_headers).to be_nil
    end
  end

  describe "#http_body" do
    it 'return from response.body' do
      e = RestMan::Exception.new(double("response", body: 'body'))
      expect(e.http_body).to eq("body")
    end

    it 'return nil when response is nil' do
      e = RestMan::Exception.new
      expect(e.http_body).to be_nil
    end
  end

end
