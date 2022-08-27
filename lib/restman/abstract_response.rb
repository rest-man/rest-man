require 'cgi'
require 'http-cookie'

module RestMan

  module AbstractResponse

    attr_reader :net_http_res, :request, :start_time, :end_time, :duration

    def inspect
      raise NotImplementedError.new('must override in subclass')
    end

    # Logger from the request, potentially nil.
    def log
      request.log
    end

    def log_response
      return unless log

      code = net_http_res.code
      res_name = net_http_res.class.to_s.gsub(/\ANet::HTTP/, '')
      content_type = (net_http_res['Content-type'] || '').gsub(/;.*\z/, '')

      log << "# => #{code} #{res_name} | #{content_type} #{size} bytes, #{sprintf('%.2f', duration)}s\n"
    end

    # HTTP status code
    def code
      @code ||= @net_http_res.code.to_i
    end

    def success?
      (200..299).include?(code)
    end

    def history
      @history ||= request.redirection_history || []
    end

    # :include: _doc/lib/restman/abstract_response/headers.rdoc
    def headers
      @headers ||= AbstractResponse.beautify_headers(@net_http_res.to_hash)
    end

    # The raw headers.
    def raw_headers
      @raw_headers ||= @net_http_res.to_hash
    end

    # @param [Net::HTTPResponse] net_http_res
    # @param [RestMan::Request] request
    # @param [Time] start_time
    def response_set_vars(net_http_res, request, start_time)
      @net_http_res = net_http_res
      @request = request
      @start_time = start_time
      @end_time = Time.now

      if @start_time
        @duration = @end_time - @start_time
      else
        @duration = nil
      end

      # prime redirection history
      history
    end

    # :include: _doc/lib/restman/abstract_response/cookies.rdoc
    def cookies
      hash = {}

      cookie_jar.cookies(@request.uri).each do |cookie|
        hash[cookie.name] = cookie.value
      end

      hash
    end

    # :include: _doc/lib/restman/abstract_response/cookie_jar.rdoc
    def cookie_jar
      return @cookie_jar if defined?(@cookie_jar) && @cookie_jar

      jar = @request.cookie_jar.dup
      headers.fetch(:set_cookie, []).each do |cookie|
        jar.parse(cookie, @request.uri)
      end

      @cookie_jar = jar
    end

    # :include: _doc/lib/restman/abstract_response/return.rdoc
    def return!(&block)
      case code
      when 200..207
        self
      when 301, 302, 307
        case request.method
        when 'get', 'head'
          check_max_redirects
          follow_redirection(&block)
        else
          raise exception_with_response
        end
      when 303
        check_max_redirects
        follow_get_redirection(&block)
      else
        raise exception_with_response
      end
    end

    def to_i
      warn('warning: calling Response#to_i is not recommended')
      super
    end

    def description
      "#{code} #{STATUSES[code]} | #{(headers[:content_type] || '').gsub(/;.*$/, '')} #{size} bytes\n"
    end

    # Follow a redirection response by making a new HTTP request to the
    # redirection target.
    def follow_redirection(&block)
      _follow_redirection(request.args.dup, &block)
    end

    # Follow a redirection response, but change the HTTP method to GET and drop
    # the payload from the original request.
    def follow_get_redirection(&block)
      new_args = request.args.dup
      new_args[:method] = :get
      new_args.delete(:payload)

      _follow_redirection(new_args, &block)
    end

    # :include: _doc/lib/restman/abstract_response/beautify_headers.rdoc
    def self.beautify_headers(headers)
      headers.inject({}) do |out, (key, value)|
        key_sym = key.tr('-', '_').downcase.to_sym

        # Handle Set-Cookie specially since it cannot be joined by comma.
        if key.downcase == 'set-cookie'
          out[key_sym] = value
        else
          out[key_sym] = value.join(', ')
        end

        out
      end
    end

    private

    # :include: _doc/lib/restman/abstract_response/_follow_redirection.rdoc
    def _follow_redirection(new_args, &block)

      # parse location header and merge into existing URL
      url = headers[:location]

      # cannot follow redirection if there is no location header
      unless url
        raise exception_with_response
      end

      # handle relative redirects
      unless url.start_with?('http')
        url = URI.parse(request.url).merge(url).to_s
      end
      new_args[:url] = url

      new_args[:password] = request.password
      new_args[:user] = request.user
      new_args[:headers] = request.headers
      new_args[:max_redirects] = request.max_redirects - 1

      # pass through our new cookie jar
      new_args[:cookies] = cookie_jar

      # prepare new request
      new_req = Request.new(new_args)

      # append self to redirection history
      new_req.redirection_history = history + [self]

      # execute redirected request
      new_req.execute(&block)
    end

    def check_max_redirects
      if request.max_redirects <= 0
        raise exception_with_response
      end
    end

    def exception_with_response
      begin
        klass = Exceptions::EXCEPTIONS_MAP.fetch(code)
      rescue KeyError
        raise RequestFailed.new(self, code)
      end

      raise klass.new(self, code)
    end
  end
end
