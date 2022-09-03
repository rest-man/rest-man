module RestMan
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
end
