module SimpleRestClient
  module Windows
  end
end

if SimpleRestClient::Platform.windows?
  require_relative './windows/root_certs'
end
