require_relative '../_lib'

describe RestMan::RequestFailed do
  before do
    @response = double('HTTP Response', :code => '502')
  end

  it "stores the http response on the exception" do
    response = "response"
    begin
      raise RestMan::RequestFailed, response
    rescue RestMan::RequestFailed => e
      expect(e.response).to eq response
    end
  end

  it "http_code convenience method for fetching the code as an integer" do
    expect(RestMan::RequestFailed.new(@response).http_code).to eq 502
  end

  it "http_body convenience method for fetching the body (decoding when necessary)" do
    expect(RestMan::RequestFailed.new(@response).http_code).to eq 502
    expect(RestMan::RequestFailed.new(@response).message).to eq 'HTTP status code 502'
  end

  it "shows the status code in the message" do
    expect(RestMan::RequestFailed.new(@response).to_s).to match(/502/)
  end
end

describe RestMan::ResourceNotFound do
  it "also has the http response attached" do
    response = "response"
    begin
      raise RestMan::ResourceNotFound, response
    rescue RestMan::ResourceNotFound => e
      expect(e.response).to eq response
    end
  end

  it 'stores the body on the response of the exception' do
    body = "body"
    stub_request(:get, "www.example.com").to_return(:body => body, :status => 404)
    begin
      RestMan.get "www.example.com"
      raise
    rescue RestMan::ResourceNotFound => e
      expect(e.response.body).to eq body
    end
  end
end