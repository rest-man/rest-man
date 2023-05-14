require 'tempfile'
require 'set'
require 'mime/types/columnar'

module RestMan
  # :include: _doc/lib/restman/request.rdoc
  class Request

    autoload :MaybeConvertExtension, 'restman/request/maybe_convert_extension'
    autoload :StringifyHeaders, 'restman/request/stringify_headers'
    autoload :MakeCookieHeader, 'restman/request/make_cookie_header'
    autoload :MakeHeaders, 'restman/request/make_headers'
    autoload :ProxyURI, 'restman/request/proxy_uri'
    autoload :NetHTTPObject, 'restman/request/net_http_object'
    autoload :DefaultSSLCertStore, 'restman/request/default_ssl_cert_store'
    autoload :LogRequest, 'restman/request/log_request'
    autoload :FetchBodyToTempfile, 'restman/request/fetch_body_to_tempfile'
    autoload :ProcessResult, 'restman/request/process_result'

    include ActiveMethod
    include Init

    attr_reader :method, :uri, :url, :headers, :payload, :proxy,
                :user, :password, :read_timeout, :max_redirects,
                :open_timeout, :raw_response, :processed_headers, :args,
                :ssl_opts, :write_timeout, :max_retries, :keep_alive_timeout,
                :close_on_empty_response, :local_host, :local_port,

                :before_execution_proc, :block_response

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
      @uri = Init.uri(url)
      @user, @password = Init.auth(uri, args)
      @cookie_jar = Init.cookie_jar(uri, headers, args)
      @payload = Payload.generate(args[:payload])
      Init.read_timeout(args) {|value| @read_timeout = value}
      Init.open_timeout(args) {|value| @open_timeout = value}
      Init.write_timeout(args) {|value| @write_timeout = value}
      @block_response = args[:block_response]
      @raw_response = args[:raw_response] || false
      @local_host = args[:local_host]
      @local_port = args[:local_port]
      Init.keep_alive_timeout(args) {|value| @keep_alive_timeout = value}
      @close_on_empty_response = args[:close_on_empty_response]
      @stream_log_percent = Init.stream_log_percent(args)
      @proxy = args.fetch(:proxy) if args.include?(:proxy)
      @ssl_opts = Init.ssl_opts(args, uri)

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
    active_method :make_cookie_header

    # :include: _doc/lib/restman/request/make_headers.rdoc
    active_method :make_headers

    # :include: _doc/lib/restman/request/proxy_uri.rdoc
    active_method :proxy_uri, ProxyURI

    active_method :net_http_object, NetHTTPObject

    def net_http_request_class(method)
      Net::HTTP.const_get(method.capitalize, false)
    end

    # :include: _doc/lib/restman/request/default_ssl_cert_store.rdoc
    def self.default_ssl_cert_store
      DefaultSSLCertStore.call
    end

    # Default to the global logger if there's not a request-specific one
    def log
      @log || RestMan.log
    end

    active_method :log_request

    # :include: _doc/lib/restman/request/stringify_headers.rdoc
    active_method :stringify_headers

    # :include: _doc/lib/restman/request/default_headers.rdoc
    def default_headers
      {
        :accept => '*/*',
        :user_agent => RestMan::Platform.default_user_agent,
      }
    end

    active_method :transmit

    def setup_credentials(req)
      if user && !@processed_headers_lowercase.include?('authorization')
        req.basic_auth(user, password)
      end
    end

    active_method :fetch_body_to_tempfile

    # :include: _doc/lib/restman/request/process_result.rdoc
    active_method :process_result

    def parser
      URI.const_defined?(:Parser) ? URI::Parser.new : URI
    end

    # :include: _doc/lib/restman/request/maybe_convert_extension.rdoc
    active_method :maybe_convert_extension
  end
end
