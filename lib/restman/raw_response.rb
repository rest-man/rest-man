module RestMan
  # :include: _doc/lib/restman/raw_response.rdoc
  class RawResponse

    include AbstractResponse

    attr_reader :file, :request, :start_time, :end_time

    def inspect
      "<RestMan::RawResponse @code=#{code.inspect}, @file=#{file.inspect}, @request=#{request.inspect}>"
    end

    # :include: _doc/lib/restman/raw_response/new.rdoc
    def initialize(tempfile, net_http_res, request, start_time=nil)
      @file = tempfile

      # reopen the tempfile so we can read it
      @file.open

      response_set_vars(net_http_res, request, start_time)
    end

    def to_s
      body
    end

    def body
      @file.rewind
      @file.read
    end

    def size
      file.size
    end

  end
end
