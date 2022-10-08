require 'tempfile'
require 'cgi'
require 'netrc'
require 'set'
require 'mime/types/columnar'

module RestMan
  # :include: _doc/lib/restman/request.rdoc
  class Request
    include Init

    attr_reader :method, :uri, :url, :headers, :payload, :proxy,
                :user, :password, :read_timeout, :max_redirects,
                :open_timeout, :raw_response, :processed_headers, :args,
                :ssl_opts, :write_timeout, :max_retries, :keep_alive_timeout,
                :close_on_empty_response, :local_host, :local_port

    # An array of previous redirection responses
    attr_accessor :redirection_history

    def self.execute(args, & block)
      new(args).execute(& block)
    end

    SSLOptionList = %w{client_cert client_key ca_file ca_path cert_store
                       version ciphers verify_callback verify_callback_warnings
                       min_version max_version timeout}

    def inspect
      "<RestMan::Request @method=#{@method.inspect}, @url=#{@url.inspect}>"
    end

    def initialize args
      @method = Init.http_method(args)
      @headers = Init.headers(args)
      @url = Init.url(args, headers)

      @user = @password = nil
      parse_url_with_auth!(url)

      # process cookie arguments found in headers or args
      @cookie_jar = process_cookie_args!(@uri, @headers, args)

      @payload = Payload.generate(args[:payload])

      @user = args[:user] if args.include?(:user)
      @password = args[:password] if args.include?(:password)

      if args.include?(:timeout)
        @read_timeout = args[:timeout]
        @open_timeout = args[:timeout]
        @write_timeout = args[:timeout]
      end
      if args.include?(:read_timeout)
        @read_timeout = args[:read_timeout]
      end
      if args.include?(:open_timeout)
        @open_timeout = args[:open_timeout]
      end
      if args.include?(:write_timeout)
        @write_timeout = args[:write_timeout]
      end
      @block_response = args[:block_response]
      @raw_response = args[:raw_response] || false

      if args.include?(:local_host)
        @local_host = args[:local_host]
      end

      if args.include?(:local_port)
        @local_port = args[:local_port]
      end

      @keep_alive_timeout = args[:keep_alive_timeout]
      @close_on_empty_response = args[:close_on_empty_response]

      @stream_log_percent = args[:stream_log_percent] || 10
      if @stream_log_percent <= 0 || @stream_log_percent > 100
        raise ArgumentError.new(
          "Invalid :stream_log_percent #{@stream_log_percent.inspect}")
      end

      @proxy = args.fetch(:proxy) if args.include?(:proxy)

      @ssl_opts = {}

      if args.include?(:verify_ssl)
        v_ssl = args.fetch(:verify_ssl)
        if v_ssl
          if v_ssl == true
            # interpret :verify_ssl => true as VERIFY_PEER
            @ssl_opts[:verify_ssl] = OpenSSL::SSL::VERIFY_PEER
          else
            # otherwise pass through any truthy values
            @ssl_opts[:verify_ssl] = v_ssl
          end
        else
          # interpret all falsy :verify_ssl values as VERIFY_NONE
          @ssl_opts[:verify_ssl] = OpenSSL::SSL::VERIFY_NONE
        end
      else
        # if :verify_ssl was not passed, default to VERIFY_PEER
        @ssl_opts[:verify_ssl] = OpenSSL::SSL::VERIFY_PEER
      end

      SSLOptionList.each do |key|
        source_key = ('ssl_' + key).to_sym
        if args.has_key?(source_key)
          @ssl_opts[key.to_sym] = args.fetch(source_key)
        end
      end

      # Set some other default SSL options, but only if we have an HTTPS URI.
      if use_ssl?

        # If there's no CA file, CA path, or cert store provided, use default
        if !ssl_ca_file && !ssl_ca_path && !@ssl_opts.include?(:cert_store)
          @ssl_opts[:cert_store] = self.class.default_ssl_cert_store
        end
      end

      @log = args[:log]
      @max_redirects = args[:max_redirects] || 10
      @max_retries = args[:max_retries] || 1
      @processed_headers = make_headers headers
      @processed_headers_lowercase = Hash[@processed_headers.map {|k, v| [k.downcase, v]}]
      @args = args

      @before_execution_proc = args[:before_execution_proc]
    end

    def execute & block
      # With 2.0.0+, net/http accepts URI objects in requests and handles wrapping
      # IPv6 addresses in [] for use in the Host request header.
      transmit uri, net_http_request_class(method).new(uri, processed_headers), payload, & block
    ensure
      payload.close if payload
    end

    # SSL-related options
    def verify_ssl
      @ssl_opts.fetch(:verify_ssl)
    end
    SSLOptionList.each do |key|
      define_method('ssl_' + key) do
        @ssl_opts[key.to_sym]
      end
    end

    # :include: _doc/lib/restman/request/use_ssl.rdoc
    def use_ssl?
      uri.is_a?(URI::HTTPS)
    end

    # :include: _doc/lib/restman/request/cookies.rdoc
    def cookies
      hash = {}

      @cookie_jar.cookies(uri).each do |c|
        hash[c.name] = c.value
      end

      hash
    end

    # :include: _doc/lib/restman/request/cookie_jar.rdoc
    def cookie_jar
      @cookie_jar
    end

    # :include: _doc/lib/restman/request/make_cookie_header.rdoc
    def make_cookie_header
      return nil if cookie_jar.nil?

      arr = cookie_jar.cookies(url)
      return nil if arr.empty?

      return HTTP::Cookie.cookie_value(arr)
    end

    # :include: _doc/lib/restman/request/process_cookie_args.rdoc
    def process_cookie_args!(uri, headers, args)

      # Avoid ambiguity in whether options from headers or options from
      # Request#initialize should take precedence by raising ArgumentError when
      # both are present. Prior versions of rest-man claimed to give
      # precedence to init options, but actually gave precedence to headers.
      # Avoid that mess by erroring out instead.
      if headers[:cookies] && args[:cookies]
        raise ArgumentError.new(
          "Cannot pass :cookies in Request.new() and in headers hash")
      end

      cookies_data = headers.delete(:cookies) || args[:cookies]

      # return copy of cookie jar as is
      if cookies_data.is_a?(HTTP::CookieJar)
        return cookies_data.dup
      end

      # convert cookies hash into a CookieJar
      jar = HTTP::CookieJar.new

      (cookies_data || []).each do |key, val|

        # Support for Array<HTTP::Cookie> mode:
        # If key is a cookie object, add it to the jar directly and assert that
        # there is no separate val.
        if key.is_a?(HTTP::Cookie)
          if val
            raise ArgumentError.new("extra cookie val: #{val.inspect}")
          end

          jar.add(key)
          next
        end

        if key.is_a?(Symbol)
          key = key.to_s
        end

        # assume implicit domain from the request URI, and set for_domain to
        # permit subdomains
        jar.add(HTTP::Cookie.new(key, val, domain: uri.hostname.downcase,
                                 path: '/', for_domain: true))
      end

      jar
    end

    # :include: _doc/lib/restman/request/make_headers.rdoc
    def make_headers(user_headers)
      headers = stringify_headers(default_headers).merge(stringify_headers(user_headers))

      # override headers from the payload (e.g. Content-Type, Content-Length)
      if @payload
        headers = @payload.headers.merge(headers)
      end

      # merge in cookies
      cookies = make_cookie_header
      if cookies && !cookies.empty?
        if headers['Cookie']
          warn('warning: overriding "Cookie" header with :cookies option')
        end
        headers['Cookie'] = cookies
      end

      headers
    end

    # :include: _doc/lib/restman/request/proxy_uri.rdoc
    def proxy_uri
      if defined?(@proxy)
        if @proxy
          URI.parse(@proxy)
        else
          false
        end
      elsif RestMan.proxy_set?
        if RestMan.proxy
          URI.parse(RestMan.proxy)
        else
          false
        end
      else
        nil
      end
    end

    def net_http_object(hostname, port)
      p_uri = proxy_uri

      if p_uri.nil?
        # no proxy set
        Net::HTTP.new(hostname, port)
      elsif !p_uri
        # proxy explicitly set to none
        Net::HTTP.new(hostname, port, nil, nil, nil, nil)
      else
        Net::HTTP.new(hostname, port,
                      p_uri.hostname, p_uri.port, p_uri.user, p_uri.password)

      end
    end

    def net_http_request_class(method)
      Net::HTTP.const_get(method.capitalize, false)
    end

    def net_http_do_request(http, req, body=nil, &block)
      if body && body.respond_to?(:read)
        req.body_stream = body
        return http.request(req, nil, &block)
      else
        return http.request(req, body, &block)
      end
    end

    # :include: _doc/lib/restman/request/default_ssl_cert_store.rdoc
    def self.default_ssl_cert_store
      cert_store = OpenSSL::X509::Store.new
      cert_store.set_default_paths

      # set_default_paths() doesn't do anything on Windows, so look up
      # certificates using the win32 API.
      if RestMan::Platform.windows?
        RestMan::Windows::RootCerts.instance.to_a.uniq.each do |cert|
          begin
            cert_store.add_cert(cert)
          rescue OpenSSL::X509::StoreError => err
            # ignore duplicate certs
            raise unless err.message == 'cert already in hash table'
          end
        end
      end

      cert_store
    end

    def redacted_uri
      if uri.password
        sanitized_uri = uri.dup
        sanitized_uri.password = 'REDACTED'
        sanitized_uri
      else
        uri
      end
    end

    def redacted_url
      redacted_uri.to_s
    end

    # Default to the global logger if there's not a request-specific one
    def log
      @log || RestMan.log
    end

    def log_request
      return unless log

      out = []

      out << "RestMan.#{method} #{redacted_url.inspect}"
      out << payload.short_inspect if payload
      out << processed_headers.to_a.sort.map { |(k, v)| [k.inspect, v.inspect].join("=>") }.join(", ")
      log << out.join(', ') + "\n"
    end

    # :include: _doc/lib/restman/request/stringify_headers.rdoc
    def stringify_headers headers
      headers.inject({}) do |result, (key, value)|
        if key.is_a? Symbol
          key = key.to_s.split(/_/).map(&:capitalize).join('-')
        end
        if 'CONTENT-TYPE' == key.upcase
          result[key] = maybe_convert_extension(value.to_s)
        elsif 'ACCEPT' == key.upcase
          # Accept can be composed of several comma-separated values
          if value.is_a? Array
            target_values = value
          else
            target_values = value.to_s.split ','
          end
          result[key] = target_values.map { |ext|
            maybe_convert_extension(ext.to_s.strip)
          }.join(', ')
        else
          result[key] = value.to_s
        end
        result
      end
    end

    # :include: _doc/lib/restman/request/default_headers.rdoc
    def default_headers
      {
        :accept => '*/*',
        :user_agent => RestMan::Platform.default_user_agent,
      }
    end

    private

    # :include: _doc/lib/restman/request/parse_url_with_auth.rdoc
    def parse_url_with_auth!(url)
      uri = URI.parse(url)

      if uri.hostname.nil?
        raise URI::InvalidURIError.new("bad URI(no host provided): #{url}")
      end

      @user = CGI.unescape(uri.user) if uri.user
      @password = CGI.unescape(uri.password) if uri.password
      if !@user && !@password
        @user, @password = Netrc.read[uri.hostname]
      end

      @uri = uri
    end

    def print_verify_callback_warnings
      warned = false
      if RestMan::Platform.mac_mri?
        warn('warning: ssl_verify_callback return code is ignored on OS X')
        warned = true
      end
      if RestMan::Platform.jruby?
        warn('warning: SSL verify_callback may not work correctly in jruby')
        warn('see https://github.com/jruby/jruby/issues/597')
        warned = true
      end
      warned
    end

    def transmit uri, req, payload, & block

      # We set this to true in the net/http block so that we can distinguish
      # read_timeout from open_timeout. Now that we only support Ruby 2.0+,
      # this is only needed for Timeout exceptions thrown outside of Net::HTTP.
      established_connection = false

      setup_credentials req

      net = net_http_object(uri.hostname, uri.port)
      net.use_ssl = uri.is_a?(URI::HTTPS)
      net.ssl_version = ssl_version if ssl_version
      net.min_version = ssl_min_version if ssl_min_version
      net.max_version = ssl_max_version if ssl_max_version
      net.ssl_timeout = ssl_timeout if ssl_timeout
      net.ciphers = ssl_ciphers if ssl_ciphers

      net.verify_mode = verify_ssl

      net.cert = ssl_client_cert if ssl_client_cert
      net.key = ssl_client_key if ssl_client_key
      net.ca_file = ssl_ca_file if ssl_ca_file
      net.ca_path = ssl_ca_path if ssl_ca_path
      net.cert_store = ssl_cert_store if ssl_cert_store

      net.max_retries = max_retries

      net.keep_alive_timeout = keep_alive_timeout if keep_alive_timeout
      net.close_on_empty_response = close_on_empty_response if close_on_empty_response
      net.local_host = local_host if local_host
      net.local_port = local_port if local_port

      # We no longer rely on net.verify_callback for the main SSL verification
      # because it's not well supported on all platforms (see comments below).
      # But do allow users to set one if they want.
      if ssl_verify_callback
        net.verify_callback = ssl_verify_callback

        # Hilariously, jruby only calls the callback when cert_store is set to
        # something, so make sure to set one.
        # https://github.com/jruby/jruby/issues/597
        if RestMan::Platform.jruby?
          net.cert_store ||= OpenSSL::X509::Store.new
        end

        if ssl_verify_callback_warnings != false
          if print_verify_callback_warnings
            warn('pass :ssl_verify_callback_warnings => false to silence this')
          end
        end
      end

      if OpenSSL::SSL::VERIFY_PEER == OpenSSL::SSL::VERIFY_NONE
        warn('WARNING: OpenSSL::SSL::VERIFY_PEER == OpenSSL::SSL::VERIFY_NONE')
        warn('This dangerous monkey patch leaves you open to MITM attacks!')
        warn('Try passing :verify_ssl => false instead.')
      end

      if defined? @read_timeout
        if @read_timeout == -1
          warn 'Deprecated: to disable timeouts, please use nil instead of -1'
          @read_timeout = nil
        end
        net.read_timeout = @read_timeout
      end
      if defined? @open_timeout
        if @open_timeout == -1
          warn 'Deprecated: to disable timeouts, please use nil instead of -1'
          @open_timeout = nil
        end
        net.open_timeout = @open_timeout
      end
      if defined? @write_timeout
        if @write_timeout == -1
          warn 'Deprecated: to disable timeouts, please use nil instead of -1'
          @write_timeout = nil
        end
        net.write_timeout = @write_timeout
      end

      RestMan.before_execution_procs.each do |before_proc|
        before_proc.call(req, args)
      end

      if @before_execution_proc
        @before_execution_proc.call(req, args)
      end

      log_request

      start_time = Time.now
      tempfile = nil

      net.start do |http|
        established_connection = true

        if @block_response
          net_http_do_request(http, req, payload, &@block_response)
        else
          res = net_http_do_request(http, req, payload) { |http_response|
            if @raw_response
              # fetch body into tempfile
              tempfile = fetch_body_to_tempfile(http_response)
            else
              # fetch body
              http_response.read_body
            end
            http_response
          }
          process_result(res, start_time, tempfile, &block)
        end
      end
    rescue EOFError
      raise RestMan::ServerBrokeConnection
    rescue Net::OpenTimeout => err
      raise RestMan::Exceptions::OpenTimeout.new(nil, err)
    rescue Net::ReadTimeout => err
      raise RestMan::Exceptions::ReadTimeout.new(nil, err)
    rescue Net::WriteTimeout => err
      raise RestMan::Exceptions::WriteTimeout.new(nil, err)
    rescue Timeout::Error, Errno::ETIMEDOUT => err
      # handling for non-Net::HTTP timeouts
      if established_connection
        raise RestMan::Exceptions::ReadTimeout.new(nil, err)
      else
        raise RestMan::Exceptions::OpenTimeout.new(nil, err)
      end
    end

    def setup_credentials(req)
      if user && !@processed_headers_lowercase.include?('authorization')
        req.basic_auth(user, password)
      end
    end

    def fetch_body_to_tempfile(http_response)
      # Taken from Chef, which as in turn...
      # Stolen from http://www.ruby-forum.com/topic/166423
      # Kudos to _why!
      tf = Tempfile.new('rest-man.')
      tf.binmode

      size = 0
      total = http_response['Content-Length'].to_i
      stream_log_bucket = nil

      http_response.read_body do |chunk|
        tf.write chunk
        size += chunk.size
        if log
          if total == 0
            log << "streaming %s %s (%d of unknown) [0 Content-Length]\n" % [@method.upcase, @url, size]
          else
            percent = (size * 100) / total
            current_log_bucket, _ = percent.divmod(@stream_log_percent)
            if current_log_bucket != stream_log_bucket
              stream_log_bucket = current_log_bucket
              log << "streaming %s %s %d%% done (%d of %d)\n" % [@method.upcase, @url, (size * 100) / total, size, total]
            end
          end
        end
      end
      tf.close
      tf
    end

    # :include: _doc/lib/restman/request/process_result.rdoc
    def process_result(res, start_time, tempfile=nil, &block)
      if @raw_response
        unless tempfile
          raise ArgumentError.new('tempfile is required')
        end
        response = RawResponse.new(tempfile, res, self, start_time)
      else
        response = Response.create(res.body, res, self, start_time)
      end

      response.log_response

      if block_given?
        block.call(response, self, res, & block)
      else
        response.return!(&block)
      end

    end

    def parser
      URI.const_defined?(:Parser) ? URI::Parser.new : URI
    end

    # :include: _doc/lib/restman/request/maybe_convert_extension.rdoc
    def maybe_convert_extension(ext)
      unless ext =~ /\A[a-zA-Z0-9_@-]+\z/
        # Don't look up strings unless they look like they could be a file
        # extension known to mime-types.
        #
        # There currently isn't any API public way to look up extensions
        # directly out of MIME::Types, but the type_for() method only strips
        # off after a period anyway.
        return ext
      end

      types = MIME::Types.type_for(ext)
      if types.empty?
        ext
      else
        types.first.content_type
      end
    end
  end
end
