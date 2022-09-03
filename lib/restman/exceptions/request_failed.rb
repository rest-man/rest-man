module RestMan

  # :include: _doc/lib/restman/exceptions.rdoc
  module Exceptions
    # Map http status codes to the corresponding exception class
    EXCEPTIONS_MAP = {}
  end

  # The request failed with an error code not managed by the code
  class RequestFailed < ExceptionWithResponse

    def default_message
      "HTTP status code #{http_code}"
    end

    def to_s
      message
    end
  end

  # Create HTTP status exception classes
  STATUSES.each_pair do |code, message|
    klass = Class.new(RequestFailed) do
      send(:define_method, :default_message) {"#{http_code ? "#{http_code} " : ''}#{message}"}
    end
    klass_constant = const_set(message.delete(' \-\''), klass)
    Exceptions::EXCEPTIONS_MAP[code] = klass_constant
  end

  # Create HTTP status exception classes used for backwards compatibility
  STATUSES_COMPATIBILITY.each_pair do |code, compat_list|
    klass = Exceptions::EXCEPTIONS_MAP.fetch(code)
    compat_list.each do |old_name|
      const_set(old_name, klass)
    end
  end

end
