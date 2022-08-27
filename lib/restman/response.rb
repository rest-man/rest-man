module RestMan

  # A Response from RestMan, you can access the response body, the code or the headers.
  #
  class Response < String

    include AbstractResponse

    # :include: _doc/lib/restman/response/body.rdoc
    def body
      # Benchmarking suggests that "#{self}" is fastest, and that caching the
      # body string in an instance variable doesn't make it enough faster to be
      # worth the extra memory storage.
      String.new(self)
    end

    # Convert the HTTP response body to a pure String object.
    def to_s
      body
    end

    # Convert the HTTP response body to a pure String object.
    def to_str
      body
    end

    def inspect
      "<RestMan::Response #{code.inspect} #{body_truncated(10).inspect}>"
    end

    # :include: _doc/lib/restman/response/create.rdoc
    def self.create(body, net_http_res, request, start_time=nil)
      result = self.new(body || '')

      result.response_set_vars(net_http_res, request, start_time)
      fix_encoding(result)

      result
    end

    # Set the String encoding according to the 'Content-Type: charset' header,
    # if possible.
    def self.fix_encoding(response)
      charset = RestMan::Utils.get_encoding_from_headers(response.headers)
      encoding = nil

      begin
        encoding = Encoding.find(charset) if charset
      rescue ArgumentError
        if response.log
          response.log << "No such encoding: #{charset.inspect}"
        end
      end

      return unless encoding

      response.force_encoding(encoding)

      response
    end

    private

    def body_truncated(length)
      b = body
      if b.length > length
        b[0..length] + '...'
      else
        b
      end
    end
  end
end
