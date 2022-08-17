require_relative '_lib'

describe SimpleRestClient::Exception do
  it "returns a 'message' equal to the class name if the message is not set, because 'message' should not be nil" do
    e = SimpleRestClient::Exception.new
    expect(e.message).to eq "SimpleRestClient::Exception"
  end

  it "returns the 'message' that was set" do
    e = SimpleRestClient::Exception.new
    message = "An explicitly set message"
    e.message = message
    expect(e.message).to eq message
  end

  it "sets the exception message to ErrorMessage" do
    expect(SimpleRestClient::ResourceNotFound.new.message).to eq 'Not Found'
  end

  it "contains exceptions in SimpleRestClient" do
    expect(SimpleRestClient::Unauthorized.new).to be_a_kind_of(SimpleRestClient::Exception)
    expect(SimpleRestClient::ServerBrokeConnection.new).to be_a_kind_of(SimpleRestClient::Exception)
  end
end

describe SimpleRestClient::ServerBrokeConnection do
  it "should have a default message of 'Server broke connection'" do
    e = SimpleRestClient::ServerBrokeConnection.new
    expect(e.message).to eq 'Server broke connection'
  end
end

describe SimpleRestClient::RequestFailed do
  before do
    @response = double('HTTP Response', :code => '502')
  end

  it "stores the http response on the exception" do
    response = "response"
    begin
      raise SimpleRestClient::RequestFailed, response
    rescue SimpleRestClient::RequestFailed => e
      expect(e.response).to eq response
    end
  end

  it "http_code convenience method for fetching the code as an integer" do
    expect(SimpleRestClient::RequestFailed.new(@response).http_code).to eq 502
  end

  it "http_body convenience method for fetching the body (decoding when necessary)" do
    expect(SimpleRestClient::RequestFailed.new(@response).http_code).to eq 502
    expect(SimpleRestClient::RequestFailed.new(@response).message).to eq 'HTTP status code 502'
  end

  it "shows the status code in the message" do
    expect(SimpleRestClient::RequestFailed.new(@response).to_s).to match(/502/)
  end
end

describe SimpleRestClient::ResourceNotFound do
  it "also has the http response attached" do
    response = "response"
    begin
      raise SimpleRestClient::ResourceNotFound, response
    rescue SimpleRestClient::ResourceNotFound => e
      expect(e.response).to eq response
    end
  end

  it 'stores the body on the response of the exception' do
    body = "body"
    stub_request(:get, "www.example.com").to_return(:body => body, :status => 404)
    begin
      SimpleRestClient.get "www.example.com"
      raise
    rescue SimpleRestClient::ResourceNotFound => e
      expect(e.response.body).to eq body
    end
  end
end

describe "backwards compatibility" do
  it 'aliases SimpleRestClient::NotFound as ResourceNotFound' do
    expect(SimpleRestClient::ResourceNotFound).to eq SimpleRestClient::NotFound
  end

  it 'aliases old names for HTTP 413, 414, 416' do
    expect(SimpleRestClient::RequestEntityTooLarge).to eq SimpleRestClient::PayloadTooLarge
    expect(SimpleRestClient::RequestURITooLong).to eq SimpleRestClient::URITooLong
    expect(SimpleRestClient::RequestedRangeNotSatisfiable).to eq SimpleRestClient::RangeNotSatisfiable
  end

  it 'subclasses NotFound from RequestFailed, ExceptionWithResponse' do
    expect(SimpleRestClient::NotFound).to be < SimpleRestClient::RequestFailed
    expect(SimpleRestClient::NotFound).to be < SimpleRestClient::ExceptionWithResponse
  end

  it 'subclasses timeout from SimpleRestClient::RequestTimeout, RequestFailed, EWR' do
    expect(SimpleRestClient::Exceptions::OpenTimeout).to be < SimpleRestClient::Exceptions::Timeout
    expect(SimpleRestClient::Exceptions::ReadTimeout).to be < SimpleRestClient::Exceptions::Timeout

    expect(SimpleRestClient::Exceptions::Timeout).to be < SimpleRestClient::RequestTimeout
    expect(SimpleRestClient::Exceptions::Timeout).to be < SimpleRestClient::RequestFailed
    expect(SimpleRestClient::Exceptions::Timeout).to be < SimpleRestClient::ExceptionWithResponse
  end

end
