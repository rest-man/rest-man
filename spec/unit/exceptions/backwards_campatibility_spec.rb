require_relative '../_lib'

describe "backwards compatibility" do
  it 'aliases RestMan::NotFound as ResourceNotFound' do
    expect(RestMan::ResourceNotFound).to eq RestMan::NotFound
  end

  it 'aliases old names for HTTP 413, 414, 416' do
    expect(RestMan::RequestEntityTooLarge).to eq RestMan::PayloadTooLarge
    expect(RestMan::RequestURITooLong).to eq RestMan::URITooLong
    expect(RestMan::RequestedRangeNotSatisfiable).to eq RestMan::RangeNotSatisfiable
  end

  it 'subclasses NotFound from RequestFailed, ExceptionWithResponse' do
    expect(RestMan::NotFound).to be < RestMan::RequestFailed
    expect(RestMan::NotFound).to be < RestMan::ExceptionWithResponse
  end

  it 'subclasses timeout from RestMan::RequestTimeout, RequestFailed, EWR' do
    expect(RestMan::Exceptions::OpenTimeout).to be < RestMan::Exceptions::Timeout
    expect(RestMan::Exceptions::ReadTimeout).to be < RestMan::Exceptions::Timeout

    expect(RestMan::Exceptions::Timeout).to be < RestMan::RequestTimeout
    expect(RestMan::Exceptions::Timeout).to be < RestMan::RequestFailed
    expect(RestMan::Exceptions::Timeout).to be < RestMan::ExceptionWithResponse
  end

end

