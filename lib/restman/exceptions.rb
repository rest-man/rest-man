module RestMan

  STATUSES_COMPATIBILITY = {
    # The RFCs all specify "Not Found", but "Resource Not Found" was used in
    # earlier RestMan releases.
    404 => ['ResourceNotFound'],

    # HTTP 413 was renamed to "Payload Too Large" in RFC7231.
    413 => ['RequestEntityTooLarge'],

    # HTTP 414 was renamed to "URI Too Long" in RFC7231.
    414 => ['RequestURITooLong'],

    # HTTP 416 was renamed to "Range Not Satisfiable" in RFC7233.
    416 => ['RequestedRangeNotSatisfiable'],
  }


  # :include: _doc/lib/restman/exception.rdoc
  class Exception < RuntimeError
    attr_accessor :response
    attr_accessor :original_exception
    attr_writer :message

    def initialize response = nil, initial_response_code = nil
      @response = response
      @message = nil
      @initial_response_code = initial_response_code
    end

    def http_code
      # return integer for compatibility
      if @response
        @response.code.to_i
      else
        @initial_response_code
      end
    end

    def http_headers
      @response.headers if @response
    end

    def http_body
      @response.body if @response
    end

    def to_s
      message
    end

    def message
      @message || default_message
    end

    def default_message
      self.class.name
    end
  end

  # Compatibility
  class ExceptionWithResponse < RestMan::Exception
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

  # :include: _doc/lib/restman/exceptions.rdoc
  module Exceptions
    # Map http status codes to the corresponding exception class
    EXCEPTIONS_MAP = {}
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

  module Exceptions
    # We have to split the Exceptions module like we do here because the
    # EXCEPTIONS_MAP is under Exceptions, but we depend on
    # RestMan::RequestTimeout below.

    # :include: _doc/lib/restman/exceptions/timeout.rdoc
    class Timeout < RestMan::RequestTimeout
      def initialize(message=nil, original_exception=nil)
        super(nil, nil)
        self.message = message if message
        self.original_exception = original_exception if original_exception
      end
    end

    # Timeout when connecting to a server. Typically wraps Net::OpenTimeout
    class OpenTimeout < Timeout
      def default_message
        'Timed out connecting to server'
      end
    end

    # Timeout when reading from a server. Typically wraps Net::ReadTimeout
    class ReadTimeout < Timeout
      def default_message
        'Timed out reading data from server'
      end
    end

    # Timeout when writing to a server. Typically wraps Net::WriteTimeout
    class WriteTimeout < Timeout
      def default_message
        'Timed out writing data to server'
      end
    end
  end


  # The server broke the connection prior to the request completing.  Usually
  # this means it crashed, or sometimes that your network connection was
  # severed before it could complete.
  class ServerBrokeConnection < RestMan::Exception
    def initialize(message = 'Server broke connection')
      super nil, nil
      self.message = message
    end
  end

end
