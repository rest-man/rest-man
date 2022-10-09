require_relative './_lib'

describe RestMan::Request, :include_helpers do
  before do
    @request = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload')

    @uri = double("uri")
    allow(@uri).to receive(:request_uri).and_return('/resource')
    allow(@uri).to receive(:hostname).and_return('some')
    allow(@uri).to receive(:port).and_return(80)

    @net = double("net::http base")
    @http = double("net::http connection")

    allow(Net::HTTP).to receive(:new).and_return(@net)

    allow(@net).to receive(:start).and_yield(@http)
    allow(@net).to receive(:use_ssl=)
    allow(@net).to receive(:verify_mode=)
    allow(@net).to receive(:verify_callback=)
    allow(@net).to receive(:ciphers=)
    allow(@net).to receive(:cert_store=)
    allow(@net).to receive(:max_retries=)
    RestMan.log = nil
  end

  it "accept */* mimetype" do
    expect(@request.default_headers[:accept]).to eq '*/*'
  end

  it "processes a successful result" do
    res = res_double
    allow(res).to receive(:code).and_return("200")
    allow(res).to receive(:body).and_return('body')
    allow(res).to receive(:[]).with('content-encoding').and_return(nil)
    expect(@request.send(:process_result, res, Time.now).body).to eq 'body'
    expect(@request.send(:process_result, res, Time.now).to_s).to eq 'body'
  end

  it "doesn't classify successful requests as failed" do
    203.upto(207) do |code|
      res = res_double
      allow(res).to receive(:code).and_return(code.to_s)
      allow(res).to receive(:body).and_return("")
      allow(res).to receive(:[]).with('content-encoding').and_return(nil)
      expect(@request.send(:process_result, res, Time.now)).to be_empty
    end
  end

  describe "user - password" do
    it "extracts the username and password when parsing http://user:password@example.com/" do
      request = RestMan::Request.new(method: :get, url: 'http://joe:pass1@example.com/resource')
      expect(request.user).to eq 'joe'
      expect(request.password).to eq 'pass1'
    end

    it "extracts with escaping the username and password when parsing http://user:password@example.com/" do
      request = RestMan::Request.new(method: :get, url: 'http://joe%20:pass1@example.com/resource')
      expect(request.user).to eq 'joe '
      expect(request.password).to eq 'pass1'
    end

    it "doesn't overwrite user and password (which may have already been set by the Resource constructor) if there is no user/password in the url" do
      request = RestMan::Request.new(method: :get, url: 'http://example.com/resource', user: 'beth', password: 'pass2')
      expect(request.user).to eq 'beth'
      expect(request.password).to eq 'pass2'
    end

    it 'uses the username and password from the URL' do
      request = RestMan::Request.new(method: :get, url: 'http://person:secret@example.com/resource')
      expect(request.user).to eq 'person'
      expect(request.password).to eq 'secret'
    end

    it 'overrides URL user/pass with explicit options' do
      request = RestMan::Request.new(method: :get, url: 'http://person:secret@example.com/resource', user: 'beth', password: 'pass2')
      expect(request.user).to eq 'beth'
      expect(request.password).to eq 'pass2'
    end
  end

  it "correctly formats cookies provided to the constructor" do
    cookies_arr = [
      HTTP::Cookie.new('session_id', '1', domain: 'example.com', path: '/'),
      HTTP::Cookie.new('user_id', 'someone', domain: 'example.com', path: '/'),
    ]

    jar = HTTP::CookieJar.new
    cookies_arr.each {|c| jar << c }

    # test Hash, HTTP::CookieJar, and Array<HTTP::Cookie> modes
    [
      {session_id: '1', user_id: 'someone'},
      jar,
      cookies_arr
    ].each do |cookies|
      [true, false].each do |in_headers|
        if in_headers
          opts = {headers: {cookies: cookies}}
        else
          opts = {cookies: cookies}
        end

        request = RestMan::Request.new(method: :get, url: 'example.com', **opts)
        expect(request).to receive(:default_headers).and_return({'Foo' => 'bar'})
        expect(request.make_headers({})).to eq({'Foo' => 'bar', 'Cookie' => 'session_id=1; user_id=someone'})
        expect(request.make_cookie_header).to eq 'session_id=1; user_id=someone'
        expect(request.cookies).to eq({'session_id' => '1', 'user_id' => 'someone'})
        expect(request.cookie_jar.cookies.length).to eq 2
        expect(request.cookie_jar.object_id).not_to eq jar.object_id # make sure we dup it
      end
    end

    # test with no cookies
    request = RestMan::Request.new(method: :get, url: 'example.com')
    expect(request).to receive(:default_headers).and_return({'Foo' => 'bar'})
    expect(request.make_headers({})).to eq({'Foo' => 'bar'})
    expect(request.make_cookie_header).to be_nil
    expect(request.cookies).to eq({})
    expect(request.cookie_jar.cookies.length).to eq 0
  end

  it 'strips out cookies set for a different domain name' do
    jar = HTTP::CookieJar.new
    jar << HTTP::Cookie.new('session_id', '1', domain: 'other.example.com', path: '/')
    jar << HTTP::Cookie.new('user_id', 'someone', domain: 'other.example.com', path: '/')

    request = RestMan::Request.new(method: :get, url: 'www.example.com', cookies: jar)
    expect(request).to receive(:default_headers).and_return({'Foo' => 'bar'})
    expect(request.make_headers({})).to eq({'Foo' => 'bar'})
    expect(request.make_cookie_header).to eq nil
    expect(request.cookies).to eq({})
    expect(request.cookie_jar.cookies.length).to eq 2
  end

  it 'assumes default domain and path for cookies set by hash' do
    request = RestMan::Request.new(method: :get, url: 'www.example.com', cookies: {'session_id' => '1'})
    expect(request.cookie_jar.cookies.length).to eq 1

    cookie = request.cookie_jar.cookies.first
    expect(cookie).to be_a(HTTP::Cookie)
    expect(cookie.domain).to eq('www.example.com')
    expect(cookie.for_domain?).to be_truthy
    expect(cookie.path).to eq('/')
  end

  it 'rejects or warns with contradictory cookie options' do
    # same opt in two different places
    expect {
      RestMan::Request.new(method: :get, url: 'example.com',
                              cookies: {bar: '456'},
                              headers: {cookies: {foo: '123'}})
    }.to raise_error(ArgumentError, /Cannot pass :cookies in Request.*headers/)

    # :cookies opt and Cookie header
    [
      {cookies: {foo: '123'}, headers: {cookie: 'foo'}},
      {cookies: {foo: '123'}, headers: {'Cookie' => 'foo'}},
      {headers: {cookies: {foo: '123'}, cookie: 'foo'}},
      {headers: {cookies: {foo: '123'}, 'Cookie' => 'foo'}},
    ].each do |opts|
      expect(fake_stderr {
        RestMan::Request.new(method: :get, url: 'example.com', **opts)
      }).to match(/warning: overriding "Cookie" header with :cookies option/)
    end
  end

  it "does not escape or unescape cookies" do
    cookie = 'Foo%20:Bar%0A~'
    @request = RestMan::Request.new(:method => 'get', :url => 'example.com',
                                       :cookies => {:test => cookie})
    expect(@request).to receive(:default_headers).and_return({'Foo' => 'bar'})
    expect(@request.make_headers({})).to eq({
      'Foo' => 'bar',
      'Cookie' => "test=#{cookie}"
    })
  end

  it "rejects cookie names containing invalid characters" do
    # Cookie validity is something of a mess, but we should reject the worst of
    # the RFC 6265 (4.1.1) prohibited characters such as control characters.

    ['foo=bar', 'foo;bar', "foo\nbar"].each do |cookie_name|
      expect {
        RestMan::Request.new(:method => 'get', :url => 'example.com',
                                :cookies => {cookie_name => 'value'})
      }.to raise_error(ArgumentError, /\AInvalid cookie name/i)
    end

    cookie_name = ''
    expect {
      RestMan::Request.new(:method => 'get', :url => 'example.com',
                              :cookies => {cookie_name => 'value'})
    }.to raise_error(ArgumentError, /cookie name cannot be empty/i)
  end

  it "rejects cookie values containing invalid characters" do
    # Cookie validity is something of a mess, but we should reject the worst of
    # the RFC 6265 (4.1.1) prohibited characters such as control characters.

    ["foo\tbar", "foo\nbar"].each do |cookie_value|
      expect {
        RestMan::Request.new(:method => 'get', :url => 'example.com',
                                :cookies => {'test' => cookie_value})
      }.to raise_error(ArgumentError, /\AInvalid cookie value/i)
    end
  end

  it "does not override headers" do
    request = RestMan::Request.new(
      method: :post,
      url: 'example.com',
      payload: {'foo' => '123456'},
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8' }
    )
    expect(request.processed_headers['Content-Type']).to eq('application/x-www-form-urlencoded; charset=UTF-8')
  end

  it 'does not warn for a normal looking payload' do
    expect(fake_stderr {
      RestMan::Request.new(method: :post, url: 'example.com', payload: 'payload')
      RestMan::Request.new(method: :post, url: 'example.com', payload: 'payload', headers: {content_type: :json})
      RestMan::Request.new(method: :post, url: 'example.com', payload: {'foo' => 'bar'})
    }).to eq ''
  end

  it "uses netrc credentials" do
    expect(Netrc).to receive(:read).and_return('example.com' => ['a', 'b'])
    request = RestMan::Request.new(:method => :put, :url => 'http://example.com/', :payload => 'payload')
    expect(request.user).to eq 'a'
    expect(request.password).to eq 'b'
  end

  it "uses credentials in the url in preference to netrc" do
    allow(Netrc).to receive(:read).and_return('example.com' => ['a', 'b'])
    request = RestMan::Request.new(:method => :put, :url =>  'http://joe%20:pass1@example.com/', :payload => 'payload')
    expect(request.user).to eq 'joe '
    expect(request.password).to eq 'pass1'
  end

  it "determines the Net::HTTP class to instantiate by the method name" do
    expect(@request.net_http_request_class(:put)).to eq Net::HTTP::Put
  end

  describe "user headers" do
    it "merges user headers with the default headers" do
      expect(@request).to receive(:default_headers).and_return({:accept => '*/*'})
      headers = @request.make_headers("Accept" => "application/json", :accept_encoding => 'gzip')
      expect(headers).to have_key "Accept-Encoding"
      expect(headers["Accept-Encoding"]).to eq "gzip"
      expect(headers).to have_key "Accept"
      expect(headers["Accept"]).to eq "application/json"
    end

    it "prefers the user header when the same header exists in the defaults" do
      expect(@request).to receive(:default_headers).and_return({ '1' => '2' })
      headers = @request.make_headers('1' => '3')
      expect(headers).to have_key('1')
      expect(headers['1']).to eq '3'
    end

    it "converts user headers to string before calling CGI::unescape which fails on non string values" do
      expect(@request).to receive(:default_headers).and_return({ '1' => '2' })
      headers = @request.make_headers('1' => 3)
      expect(headers).to have_key('1')
      expect(headers['1']).to eq '3'
    end
  end

  describe "header symbols" do

    it "converts header symbols from :content_type to 'Content-Type'" do
      expect(@request).to receive(:default_headers).and_return({})
      headers = @request.make_headers(:content_type => 'abc')
      expect(headers).to have_key('Content-Type')
      expect(headers['Content-Type']).to eq 'abc'
    end

    it "converts content-type from extension to real content-type" do
      expect(@request).to receive(:default_headers).and_return({})
      headers = @request.make_headers(:content_type => 'json')
      expect(headers).to have_key('Content-Type')
      expect(headers['Content-Type']).to eq 'application/json'
    end

    it "converts accept from extension(s) to real content-type(s)" do
      expect(@request).to receive(:default_headers).and_return({})
      headers = @request.make_headers(:accept => 'json, mp3')
      expect(headers).to have_key('Accept')
      expect(headers['Accept']).to eq 'application/json, audio/mpeg'

      expect(@request).to receive(:default_headers).and_return({})
      headers = @request.make_headers(:accept => :json)
      expect(headers).to have_key('Accept')
      expect(headers['Accept']).to eq 'application/json'
    end

    it "only convert symbols in header" do
      expect(@request).to receive(:default_headers).and_return({})
      headers = @request.make_headers({:foo_bar => 'value', "bar_bar" => 'value'})
      expect(headers['Foo-Bar']).to eq 'value'
      expect(headers['bar_bar']).to eq 'value'
    end

    it "converts header values to strings" do
      expect(@request.make_headers('A' => 1)['A']).to eq '1'
    end
  end

  it "executes by constructing the Net::HTTP object, headers, and payload and calling transmit" do
    klass = double("net:http class")
    expect(@request).to receive(:net_http_request_class).with('put').and_return(klass)
    expect(klass).to receive(:new).and_return('result')
    expect(@request).to receive(:transmit).with(@request.uri, 'result', kind_of(RestMan::Payload::Base))
    @request.execute
  end

  it "IPv6: executes by constructing the Net::HTTP object, headers, and payload and calling transmit" do
    @request = RestMan::Request.new(:method => :put, :url => 'http://[::1]/some/resource', :payload => 'payload')
    klass = double("net:http class")
    expect(@request).to receive(:net_http_request_class).with('put').and_return(klass)

    if RUBY_VERSION >= "2.0.0"
      expect(klass).to receive(:new).with(kind_of(URI), kind_of(Hash)).and_return('result')
    else
      expect(klass).to receive(:new).with(kind_of(String), kind_of(Hash)).and_return('result')
    end

    expect(@request).to receive(:transmit)
    @request.execute
  end

  # TODO: almost none of these tests should actually call transmit, which is
  # part of the private API

  it "transmits the request with Net::HTTP" do
    expect(@http).to receive(:request).with('req', 'payload')
    expect(@request).to receive(:process_result)
    @request.send(:transmit, @uri, 'req', 'payload')
  end

  # TODO: most of these payload tests are historical relics that actually
  # belong in payload_spec.rb. Or we need new tests that actually cover the way
  # that Request#initialize or Request#execute uses the payload.
  describe "payload" do
    it "sends nil payloads" do
      expect(@http).to receive(:request).with('req', nil)
      expect(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', nil)
    end

    it "passes non-hash payloads straight through" do
      expect(RestMan::Payload.generate("x").to_s).to eq "x"
    end

    it "converts a hash payload to urlencoded data" do
      expect(RestMan::Payload.generate(:a => 'b c+d').to_s).to eq "a=b+c%2Bd"
    end

    it "accepts nested hashes in payload" do
      payload = RestMan::Payload.generate(:user => { :name => 'joe', :location => { :country => 'USA', :state => 'CA' }}).to_s
      expect(payload).to include('user[name]=joe')
      expect(payload).to include('user[location][country]=USA')
      expect(payload).to include('user[location][state]=CA')
    end
  end

  it "set urlencoded content_type header on hash payloads" do
    req = RestMan::Request.new(method: :post, url: 'http://some/resource', payload: {a: 1})
    expect(req.processed_headers.fetch('Content-Type')).to eq 'application/x-www-form-urlencoded'
  end

  describe "credentials" do
    it "sets up the credentials prior to the request" do
      allow(@http).to receive(:request)

      allow(@request).to receive(:process_result)

      allow(@request).to receive(:user).and_return('joe')
      allow(@request).to receive(:password).and_return('mypass')
      expect(@request).to receive(:setup_credentials).with('req')

      @request.send(:transmit, @uri, 'req', nil)
    end

    it "does not attempt to send any credentials if user is nil" do
      allow(@request).to receive(:user).and_return(nil)
      req = double("request")
      expect(req).not_to receive(:basic_auth)
      @request.send(:setup_credentials, req)
    end

    it "setup credentials when there's a user" do
      allow(@request).to receive(:user).and_return('joe')
      allow(@request).to receive(:password).and_return('mypass')
      req = double("request")
      expect(req).to receive(:basic_auth).with('joe', 'mypass')
      @request.send(:setup_credentials, req)
    end

    it "does not attempt to send credentials if Authorization header is set" do
      ['Authorization', 'authorization', 'auTHORization', :authorization].each do |authorization|
        headers = {authorization => 'Token abc123'}
        request = RestMan::Request.new(method: :get, url: 'http://some/resource', headers: headers, user: 'joe', password: 'mypass')
        req = double("net::http request")
        expect(req).not_to receive(:basic_auth)
        request.send(:setup_credentials, req)
      end
    end
  end

  it "catches EOFError and shows the more informative ServerBrokeConnection" do
    allow(@http).to receive(:request).and_raise(EOFError)
    expect { @request.send(:transmit, @uri, 'req', nil) }.to raise_error(RestMan::ServerBrokeConnection)
  end

  it "catches OpenSSL::SSL::SSLError and raise it back without more informative message" do
    allow(@http).to receive(:request).and_raise(OpenSSL::SSL::SSLError)
    expect { @request.send(:transmit, @uri, 'req', nil) }.to raise_error(OpenSSL::SSL::SSLError)
  end

  it "catches Timeout::Error and raise the more informative ReadTimeout" do
    allow(@http).to receive(:request).and_raise(Timeout::Error)
    expect { @request.send(:transmit, @uri, 'req', nil) }.to raise_error(RestMan::Exceptions::ReadTimeout)
  end

  it "catches Errno::ETIMEDOUT and raise the more informative ReadTimeout" do
    allow(@http).to receive(:request).and_raise(Errno::ETIMEDOUT)
    expect { @request.send(:transmit, @uri, 'req', nil) }.to raise_error(RestMan::Exceptions::ReadTimeout)
  end

  it "catches Net::ReadTimeout and raises RestMan's ReadTimeout",
     :if => defined?(Net::ReadTimeout) do
    allow(@http).to receive(:request).and_raise(Net::ReadTimeout)
    expect { @request.send(:transmit, @uri, 'req', nil) }.to raise_error(RestMan::Exceptions::ReadTimeout)
  end

  it "catches Net::OpenTimeout and raises RestMan's OpenTimeout",
     :if => defined?(Net::OpenTimeout) do
    allow(@http).to receive(:request).and_raise(Net::OpenTimeout)
    expect { @request.send(:transmit, @uri, 'req', nil) }.to raise_error(RestMan::Exceptions::OpenTimeout)
  end

  it "catches Net::WriteTimeout and raises RestMan's WriteTimeout",
     :if => defined?(Net::WriteTimeout) do
    allow(@http).to receive(:request).and_raise(Net::WriteTimeout)
    expect { @request.send(:transmit, @uri, 'req', nil) }.to raise_error(RestMan::Exceptions::WriteTimeout)
  end

  it "uses correct error message for ReadTimeout",
     :if => defined?(Net::ReadTimeout) do
    allow(@http).to receive(:request).and_raise(Net::ReadTimeout)
    expect { @request.send(:transmit, @uri, 'req', nil) }.to raise_error(RestMan::Exceptions::ReadTimeout, 'Timed out reading data from server')
  end

  it "uses correct error message for OpenTimeout",
     :if => defined?(Net::OpenTimeout) do
    allow(@http).to receive(:request).and_raise(Net::OpenTimeout)
    expect { @request.send(:transmit, @uri, 'req', nil) }.to raise_error(RestMan::Exceptions::OpenTimeout, 'Timed out connecting to server')
  end

  it "uses correct error message for WriteTimeout",
     :if => defined?(Net::WriteTimeout) do
    allow(@http).to receive(:request).and_raise(Net::WriteTimeout)
    expect { @request.send(:transmit, @uri, 'req', nil) }.to raise_error(RestMan::Exceptions::WriteTimeout, 'Timed out writing data to server')
  end

  it "class method execute wraps constructor" do
    req = double("rest request")
    expect(RestMan::Request).to receive(:new).with(1 => 2).and_return(req)
    expect(req).to receive(:execute)
    RestMan::Request.execute(1 => 2)
  end

  describe "exception" do
    it "raises Unauthorized when the response is 401" do
      res = res_double(:code => '401', :[] => ['content-encoding' => ''], :body => '' )
      expect { @request.send(:process_result, res, Time.now) }.to raise_error(RestMan::Unauthorized)
    end

    it "raises ResourceNotFound when the response is 404" do
      res = res_double(:code => '404', :[] => ['content-encoding' => ''], :body => '' )
      expect { @request.send(:process_result, res, Time.now) }.to raise_error(RestMan::ResourceNotFound)
    end

    it "raises RequestFailed otherwise" do
      res = res_double(:code => '500', :[] => ['content-encoding' => ''], :body => '' )
      expect { @request.send(:process_result, res, Time.now) }.to raise_error(RestMan::InternalServerError)
    end
  end

  describe "block usage" do
    it "returns what asked to" do
      res = res_double(:code => '401', :[] => ['content-encoding' => ''], :body => '' )
      expect(@request.send(:process_result, res, Time.now){|response, request| "foo"}).to eq "foo"
    end
  end

  describe "proxy" do
    before do
      # unstub Net::HTTP creation since we need to test it
      allow(Net::HTTP).to receive(:new).and_call_original

      @proxy_req = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload')
    end

    it "creates a proxy class if a proxy url is given" do
      allow(RestMan).to receive(:proxy).and_return("http://example.com/")
      allow(RestMan).to receive(:proxy_set?).and_return(true)
      expect(@proxy_req.net_http_object('host', 80).proxy?).to be true
    end

    it "creates a proxy class with the correct address if a IPv6 proxy url is given" do
      allow(RestMan).to receive(:proxy).and_return("http://[::1]/")
      allow(RestMan).to receive(:proxy_set?).and_return(true)
      expect(@proxy_req.net_http_object('host', 80).proxy?).to be true
      expect(@proxy_req.net_http_object('host', 80).proxy_address).to eq('::1')
    end

    it "creates a non-proxy class if a proxy url is not given" do
      expect(@proxy_req.net_http_object('host', 80).proxy?).to be_falsey
    end

    it "disables proxy on a per-request basis" do
      allow(RestMan).to receive(:proxy).and_return('http://example.com')
      allow(RestMan).to receive(:proxy_set?).and_return(true)
      expect(@proxy_req.net_http_object('host', 80).proxy?).to be true

      disabled_req = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :proxy => nil)
      expect(disabled_req.net_http_object('host', 80).proxy?).to be_falsey
    end

    it "sets proxy on a per-request basis" do
      expect(@proxy_req.net_http_object('some', 80).proxy?).to be_falsey

      req = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :proxy => 'http://example.com')
      expect(req.net_http_object('host', 80).proxy?).to be true
    end

    it "overrides proxy from environment", if: RUBY_VERSION >= '2.0' do
      allow(ENV).to receive(:[]).with("http_proxy").and_return("http://127.0.0.1")
      allow(ENV).to receive(:[]).with("no_proxy").and_return(nil)
      allow(ENV).to receive(:[]).with("NO_PROXY").and_return(nil)
      allow(Netrc).to receive(:read).and_return({})

      req = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload')
      obj = req.net_http_object('host', 80)
      expect(obj.proxy?).to be true
      expect(obj.proxy_address).to eq '127.0.0.1'

      # test original method .proxy?
      req = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :proxy => nil)
      obj = req.net_http_object('host', 80)
      expect(obj.proxy?).to be_falsey

      # stub RestMan.proxy_set? to peek into implementation
      allow(RestMan).to receive(:proxy_set?).and_return(true)
      req = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload')
      obj = req.net_http_object('host', 80)
      expect(obj.proxy?).to be_falsey

      # test stubbed Net::HTTP.new
      req = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :proxy => nil)
      expect(Net::HTTP).to receive(:new).with('host', 80, nil, nil, nil, nil)
      req.net_http_object('host', 80)
    end

    it "overrides global proxy with per-request proxy" do
      allow(RestMan).to receive(:proxy).and_return('http://example.com')
      allow(RestMan).to receive(:proxy_set?).and_return(true)
      obj = @proxy_req.net_http_object('host', 80)
      expect(obj.proxy?).to be true
      expect(obj.proxy_address).to eq 'example.com'

      req = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :proxy => 'http://127.0.0.1/')
      expect(req.net_http_object('host', 80).proxy?).to be true
      expect(req.net_http_object('host', 80).proxy_address).to eq('127.0.0.1')
    end
  end


  describe "logging" do
    it "logs a get request" do
      log = RestMan.log = []
      RestMan::Request.new(:method => :get, :url => 'http://url', :headers => {:user_agent => 'rest-man'}).log_request
      expect(log[0]).to eq %Q{RestMan.get "http://url", "Accept"=>"*/*", "User-Agent"=>"rest-man"\n}
    end

    it "logs a post request with a small payload" do
      log = RestMan.log = []
      RestMan::Request.new(:method => :post, :url => 'http://url', :payload => 'foo', :headers => {:user_agent => 'rest-man'}).log_request
      expect(log[0]).to eq %Q{RestMan.post "http://url", "foo", "Accept"=>"*/*", "Content-Length"=>"3", "User-Agent"=>"rest-man"\n}
    end

    it "logs a post request with a large payload" do
      log = RestMan.log = []
      RestMan::Request.new(:method => :post, :url => 'http://url', :payload => ('x' * 1000), :headers => {:user_agent => 'rest-man'}).log_request
      expect(log[0]).to eq %Q{RestMan.post "http://url", 1000 byte(s) length, "Accept"=>"*/*", "Content-Length"=>"1000", "User-Agent"=>"rest-man"\n}
    end

    it "logs input headers as a hash" do
      log = RestMan.log = []
      RestMan::Request.new(:method => :get, :url => 'http://url', :headers => { :accept => 'text/plain', :user_agent => 'rest-man' }).log_request
      expect(log[0]).to eq %Q{RestMan.get "http://url", "Accept"=>"text/plain", "User-Agent"=>"rest-man"\n}
    end

    it "logs a response including the status code, content type, and result body size in bytes" do
      log = RestMan.log = []
      res = res_double(code: '200', class: Net::HTTPOK, body: 'abcd')
      allow(res).to receive(:[]).with('Content-type').and_return('text/html')
      response = response_from_res_double(res, @request)
      response.log_response
      expect(log).to eq ["# => 200 OK | text/html 4 bytes, 1.00s\n"]
    end

    it "logs a response with a nil Content-type" do
      log = RestMan.log = []
      res = res_double(code: '200', class: Net::HTTPOK, body: 'abcd')
      allow(res).to receive(:[]).with('Content-type').and_return(nil)
      response = response_from_res_double(res, @request)
      response.log_response
      expect(log).to eq ["# => 200 OK |  4 bytes, 1.00s\n"]
    end

    it "logs a response with a nil body" do
      log = RestMan.log = []
      res = res_double(code: '200', class: Net::HTTPOK, body: nil)
      allow(res).to receive(:[]).with('Content-type').and_return('text/html; charset=utf-8')
      response = response_from_res_double(res, @request)
      response.log_response
      expect(log).to eq ["# => 200 OK | text/html 0 bytes, 1.00s\n"]
    end

    it 'does not log request password' do
      log = RestMan.log = []
      RestMan::Request.new(:method => :get, :url => 'http://user:password@url', :headers => {:user_agent => 'rest-man'}).log_request
      expect(log[0]).to eq %Q{RestMan.get "http://user:REDACTED@url", "Accept"=>"*/*", "User-Agent"=>"rest-man"\n}
    end

    it 'logs to a passed logger, if provided' do
      logger = double('logger', '<<' => true)
      expect(logger).to receive(:<<)
      RestMan::Request.new(:method => :get, :url => 'http://user:password@url', log: logger).log_request
    end
  end

  it "strips the charset from the response content type" do
    log = RestMan.log = []
    res = res_double(code: '200', class: Net::HTTPOK, body: 'abcd')
    allow(res).to receive(:[]).with('Content-type').and_return('text/html; charset=utf-8')
    response = response_from_res_double(res, @request)
    response.log_response
    expect(log).to eq ["# => 200 OK | text/html 4 bytes, 1.00s\n"]
  end

  describe "timeout" do
    it "does not set timeouts if not specified" do
      @request = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload')
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)

      expect(@net).not_to receive(:read_timeout=)
      expect(@net).not_to receive(:open_timeout=)
      expect(@net).not_to receive(:write_timeout=)

      @request.send(:transmit, @uri, 'req', nil)
    end

    it 'sets read_timeout' do
      @request = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :read_timeout => 123)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)

      expect(@net).to receive(:read_timeout=).with(123)

      @request.send(:transmit, @uri, 'req', nil)
    end

    it "sets open_timeout" do
      @request = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :open_timeout => 123)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)

      expect(@net).to receive(:open_timeout=).with(123)

      @request.send(:transmit, @uri, 'req', nil)
    end

    it "sets write_timeout" do
      @request = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :write_timeout => 123)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)

      expect(@net).to receive(:write_timeout=).with(123)

      @request.send(:transmit, @uri, 'req', nil)
    end

    it 'sets all timeouts with :timeout' do
      @request = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :timeout => 123)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)

      expect(@net).to receive(:open_timeout=).with(123)
      expect(@net).to receive(:read_timeout=).with(123)
      expect(@net).to receive(:write_timeout=).with(123)

      @request.send(:transmit, @uri, 'req', nil)
    end

    it 'supersedes :timeout with open/read/write_timeout' do
      @request = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :timeout => 123, :open_timeout => 34, :read_timeout => 56, :write_timeout => 78)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)

      expect(@net).to receive(:open_timeout=).with(34)
      expect(@net).to receive(:read_timeout=).with(56)
      expect(@net).to receive(:write_timeout=).with(78)

      @request.send(:transmit, @uri, 'req', nil)
    end


    it "disable timeout by setting it to nil" do
      @request = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :read_timeout => nil, :open_timeout => nil, :write_timeout => nil)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)

      expect(@net).to receive(:read_timeout=).with(nil)
      expect(@net).to receive(:open_timeout=).with(nil)
      expect(@net).to receive(:write_timeout=).with(nil)

      @request.send(:transmit, @uri, 'req', nil)
    end

    it 'deprecated: warns when disabling timeout by setting it to -1' do
      @request = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :read_timeout => -1)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)

      expect(@net).to receive(:read_timeout=).with(nil)

      expect(fake_stderr {
        @request.send(:transmit, @uri, 'req', nil)
      }).to match(/^Deprecated: .*timeout.* nil instead of -1$/)
    end

    it "deprecated: disable timeout by setting it to -1" do
      @request = RestMan::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :read_timeout => -1, :open_timeout => -1, :write_timeout => -1)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)

      expect(@request).to receive(:warn)
      expect(@net).to receive(:read_timeout=).with(nil)

      expect(@request).to receive(:warn)
      expect(@net).to receive(:open_timeout=).with(nil)

      expect(@request).to receive(:warn)
      expect(@net).to receive(:write_timeout=).with(nil)

      @request.send(:transmit, @uri, 'req', nil)
    end
  end

  describe "ssl" do
    it "uses SSL when the URI refers to a https address" do
      allow(@uri).to receive(:is_a?).with(URI::HTTPS).and_return(true)
      expect(@net).to receive(:use_ssl=).with(true)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should default to verifying ssl certificates" do
      expect(@request.verify_ssl).to eq OpenSSL::SSL::VERIFY_PEER
    end

    it "should have expected values for VERIFY_PEER and VERIFY_NONE" do
      expect(OpenSSL::SSL::VERIFY_NONE).to eq(0)
      expect(OpenSSL::SSL::VERIFY_PEER).to eq(1)
    end

    it "should set net.verify_mode to OpenSSL::SSL::VERIFY_NONE if verify_ssl is false" do
      @request = RestMan::Request.new(:method => :put, :verify_ssl => false, :url => 'http://some/resource', :payload => 'payload')
      expect(@net).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should not set net.verify_mode to OpenSSL::SSL::VERIFY_NONE if verify_ssl is true" do
      @request = RestMan::Request.new(:method => :put, :url => 'https://some/resource', :payload => 'payload', :verify_ssl => true)
      expect(@net).not_to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should set net.verify_mode to OpenSSL::SSL::VERIFY_PEER if verify_ssl is true" do
      @request = RestMan::Request.new(:method => :put, :url => 'https://some/resource', :payload => 'payload', :verify_ssl => true)
      expect(@net).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should set net.verify_mode to OpenSSL::SSL::VERIFY_PEER if verify_ssl is not given" do
      @request = RestMan::Request.new(:method => :put, :url => 'https://some/resource', :payload => 'payload')
      expect(@net).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should set net.verify_mode to the passed value if verify_ssl is an OpenSSL constant" do
      mode = OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
      @request = RestMan::Request.new( :method => :put,
                                          :url => 'https://some/resource',
                                          :payload => 'payload',
                                          :verify_ssl => mode )
      expect(@net).to receive(:verify_mode=).with(mode)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should set the keep_alive_timeout if provided" do
      @request = RestMan::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
        :keep_alive_timeout => 1
      )
      expect(@net).to receive(:keep_alive_timeout=).with(1)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should set the close_on_empty_response if provided" do
      @request = RestMan::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
        :close_on_empty_response => true
      )
      expect(@net).to receive(:close_on_empty_response=).with(true)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should set the local_host if provided" do
      @request = RestMan::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
        :local_host => 'localhost'
      )
      expect(@net).to receive(:local_host=).with('localhost')
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should set the local_port if provided" do
      @request = RestMan::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
        :local_port => 3000
      )
      expect(@net).to receive(:local_port=).with(3000)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should default to not having an ssl_client_cert" do
      expect(@request.ssl_client_cert).to be(nil)
    end

    it "should set the ssl_version if provided" do
      @request = RestMan::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
        :ssl_version => "TLSv1"
      )
      expect(@net).to receive(:ssl_version=).with("TLSv1")
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should not set the ssl_version if not provided" do
      @request = RestMan::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload'
      )
      expect(@net).not_to receive(:ssl_version=).with("TLSv1")
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should set the ssl_min_version if provided" do
      @request = RestMan::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
        :ssl_min_version => :TLS1_2
      )
      expect(@net).to receive(:min_version=).with(:TLS1_2)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should set the ssl_max_version if provided" do
      @request = RestMan::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
        :ssl_max_version => :TLS1_2
      )
      expect(@net).to receive(:max_version=).with(:TLS1_2)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should set the ssl_timeout if provided" do
      @request = RestMan::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
        :ssl_timeout => 1
      )
      expect(@net).to receive(:ssl_timeout=).with(1)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should set the ssl_ciphers if provided" do
      ciphers = 'AESGCM:HIGH:!aNULL:!eNULL:RC4+RSA'
      @request = RestMan::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
        :ssl_ciphers => ciphers
      )
      expect(@net).to receive(:ciphers=).with(ciphers)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should not set the ssl_ciphers if set to nil" do
      @request = RestMan::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
        :ssl_ciphers => nil,
      )
      expect(@net).not_to receive(:ciphers=)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should set the ssl_client_cert if provided" do
      @request = RestMan::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
              :ssl_client_cert => "whatsupdoc!"
      )
      expect(@net).to receive(:cert=).with("whatsupdoc!")
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should not set the ssl_client_cert if it is not provided" do
      @request = RestMan::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload'
      )
      expect(@net).not_to receive(:cert=)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should default to not having an ssl_client_key" do
      expect(@request.ssl_client_key).to be(nil)
    end

    it "should set the ssl_client_key if provided" do
      @request = RestMan::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
              :ssl_client_key => "whatsupdoc!"
      )
      expect(@net).to receive(:key=).with("whatsupdoc!")
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should not set the ssl_client_key if it is not provided" do
      @request = RestMan::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload'
      )
      expect(@net).not_to receive(:key=)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should default to not having an ssl_ca_file" do
      expect(@request.ssl_ca_file).to be(nil)
    end

    it "should set the ssl_ca_file if provided" do
      @request = RestMan::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
              :ssl_ca_file => "Certificate Authority File"
      )
      expect(@net).to receive(:ca_file=).with("Certificate Authority File")
      expect(@net).not_to receive(:cert_store=)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should not set the ssl_ca_file if it is not provided" do
      @request = RestMan::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload'
      )
      expect(@net).not_to receive(:ca_file=)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should default to not having an ssl_ca_path" do
      expect(@request.ssl_ca_path).to be(nil)
    end

    it "should set the ssl_ca_path if provided" do
      @request = RestMan::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
              :ssl_ca_path => "Certificate Authority Path"
      )
      expect(@net).to receive(:ca_path=).with("Certificate Authority Path")
      expect(@net).not_to receive(:cert_store=)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should not set the ssl_ca_path if it is not provided" do
      @request = RestMan::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload'
      )
      expect(@net).not_to receive(:ca_path=)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should set the ssl_cert_store if provided" do
      store = OpenSSL::X509::Store.new
      store.set_default_paths

      @request = RestMan::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
              :ssl_cert_store => store
      )
      expect(@net).to receive(:cert_store=).with(store)
      expect(@net).not_to receive(:ca_path=)
      expect(@net).not_to receive(:ca_file=)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should by default set the ssl_cert_store if no CA info is provided" do
      @request = RestMan::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload'
      )
      expect(@net).to receive(:cert_store=)
      expect(@net).not_to receive(:ca_path=)
      expect(@net).not_to receive(:ca_file=)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should not set the ssl_cert_store if it is set falsy" do
      @request = RestMan::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
              :ssl_cert_store => nil,
      )
      expect(@net).not_to receive(:cert_store=)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should not set the ssl_verify_callback by default" do
      @request = RestMan::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
      )
      expect(@net).not_to receive(:verify_callback=)
      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    it "should set the ssl_verify_callback if passed" do
      callback = lambda {}
      @request = RestMan::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
              :ssl_verify_callback => callback,
      )
      expect(@net).to receive(:verify_callback=).with(callback)

      # we'll read cert_store on jruby
      # https://github.com/jruby/jruby/issues/597
      if RestMan::Platform.jruby?
        allow(@net).to receive(:cert_store)
      end

      allow(@http).to receive(:request)
      allow(@request).to receive(:process_result)
      @request.send(:transmit, @uri, 'req', 'payload')
    end

    # </ssl>
  end

  it "should still return a response object for 204 No Content responses" do
    @request = RestMan::Request.new(
            :method => :put,
            :url => 'https://some/resource',
            :payload => 'payload'
    )
    net_http_res = Net::HTTPNoContent.new("", "204", "No Content")
    allow(net_http_res).to receive(:read_body).and_return(nil)
    expect(@http).to receive(:request).and_return(net_http_res)
    response = @request.send(:transmit, @uri, 'req', 'payload')
    expect(response).not_to be_nil
    expect(response.code).to eq 204
  end

  describe "raw response" do
    it "should read the response into a binary-mode tempfile" do
      @request = RestMan::Request.new(:method => "get", :url => "example.com", :raw_response => true)

      tempfile = double("tempfile")
      expect(tempfile).to receive(:binmode)
      allow(tempfile).to receive(:open)
      allow(tempfile).to receive(:close)
      expect(Tempfile).to receive(:new).with("rest-man.").and_return(tempfile)

      net_http_res = Net::HTTPOK.new(nil, "200", "body")
      allow(net_http_res).to receive(:read_body).and_return("body")
      received_tempfile = @request.send(:fetch_body_to_tempfile, net_http_res)
      expect(received_tempfile).to eq tempfile
    end
  end

  describe 'payloads' do
    it 'should accept string payloads' do
      payload = 'Foo'
      @request = RestMan::Request.new(method: :get, url: 'example.com', :payload => payload)
      expect(@request).to receive(:process_result)
      expect(@http).to receive(:request).with('req', payload)
      @request.send(:transmit, @uri, 'req', payload)
    end

    it 'should accept streaming IO payloads' do
      payload = StringIO.new('streamed')

      @request = RestMan::Request.new(method: :get, url: 'example.com', :payload => payload)
      expect(@request).to receive(:process_result)

      @get = double('net::http::get')
      expect(@get).to receive(:body_stream=).with(instance_of(RestMan::Payload::Streamed))

      allow(@request.net_http_request_class(:GET)).to receive(:new).and_return(@get)
      expect(@http).to receive(:request).with(@get, nil)
      @request.execute
    end
  end

  it 'raises with invalid URI' do
    expect {
      RestMan::Request.new(method: :get, url: 'http://a@b:c')
    }.to raise_error(URI::InvalidURIError)

    expect {
      RestMan::Request.new(method: :get, url: 'http://::')
    }.to raise_error(URI::InvalidURIError)
  end

end
