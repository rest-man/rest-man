module RestMan
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
end
