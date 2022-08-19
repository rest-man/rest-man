module RestMan
  module Windows
  end
end

if RestMan::Platform.windows?
  require_relative './windows/root_certs'
end
