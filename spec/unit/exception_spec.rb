require_relative '_lib'

describe RestMan::Exception do
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

  it "contains exceptions in RestMan" do
    expect(RestMan::Unauthorized.new).to be_a_kind_of(RestMan::Exception)
    expect(RestMan::ServerBrokeConnection.new).to be_a_kind_of(RestMan::Exception)
  end
end
