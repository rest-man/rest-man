# Simple REST Client -- simple DSL for accessing HTTP and REST resources

A simple HTTP and REST client for Ruby, inspired by the Sinatra's microframework style
of specifying actions: get, put, post, delete.

This is a fork version of [rest-client](https://github.com/rest-client/rest-client)

## Requirements

MRI Ruby 2.0 and newer are supported. Alternative interpreters compatible with
2.0+ should work as well.

Earlier Ruby versions such as 1.8.7, 1.9.2, and 1.9.3 are no longer supported. These
versions no longer have any official support, and do not receive security
updates.

The simple-rest-client gem depends on these other gems for usage at runtime:

* [mime-types](http://rubygems.org/gems/mime-types)
* [netrc](http://rubygems.org/gems/netrc)
* [http-accept](https://rubygems.org/gems/http-accept)
* [http-cookie](https://rubygems.org/gems/http-cookie)

There are also several development dependencies. It's recommended to use
[bundler](http://bundler.io/) to manage these dependencies for hacking on
simple-rest-client.

## Usage: Raw URL

Basic usage:

```ruby
require 'simple-rest-client'

SimpleRestClient.get(url, headers={})

SimpleRestClient.post(url, payload, headers={})
```

In the high level helpers, only POST, PATCH, and PUT take a payload argument.
To pass a payload with other HTTP verbs or to pass more advanced options, use
`SimpleRestClient::Request.execute` instead.

More detailed examples:

```ruby
require 'simple-rest-client'

SimpleRestClient.get 'http://example.com/resource'

SimpleRestClient.get 'http://example.com/resource', {params: {id: 50, 'foo' => 'bar'}}

SimpleRestClient.get 'https://user:password@example.com/private/resource', {accept: :json}

SimpleRestClient.post 'http://example.com/resource', {param1: 'one', nested: {param2: 'two'}}

SimpleRestClient.post "http://example.com/resource", {'x' => 1}.to_json, {content_type: :json, accept: :json}

SimpleRestClient.delete 'http://example.com/resource'

>> response = SimpleRestClient.get 'http://example.com/resource'
=> <SimpleRestClient::Response 200 "<!doctype h...">
>> response.code
=> 200
>> response.cookies
=> {"Foo"=>"BAR", "QUUX"=>"QUUUUX"}
>> response.headers
=> {:content_type=>"text/html; charset=utf-8", :cache_control=>"private" ... }
>> response.body
=> "<!doctype html>\n<html>\n<head>\n    <title>Example Domain</title>\n\n ..."

SimpleRestClient.post( url,
  {
    :transfer => {
      :path => '/foo/bar',
      :owner => 'that_guy',
      :group => 'those_guys'
    },
     :upload => {
      :file => File.new(path, 'rb')
    }
  })
```
## Passing advanced options

The top level helper methods like SimpleRestClient.get accept a headers hash as
their last argument and don't allow passing more complex options. But these
helpers are just thin wrappers around `SimpleRestClient::Request.execute`.

```ruby
SimpleRestClient::Request.execute(method: :get, url: 'http://example.com/resource',
                            timeout: 10)

SimpleRestClient::Request.execute(method: :get, url: 'http://example.com/resource',
                            ssl_ca_file: 'myca.pem',
                            ssl_ciphers: 'AESGCM:!aNULL')
```
You can also use this to pass a payload for HTTP verbs like DELETE, where the
`SimpleRestClient.delete` helper doesn't accept a payload.

```ruby
SimpleRestClient::Request.execute(method: :delete, url: 'http://example.com/resource',
                            payload: 'foo', headers: {myheader: 'bar'})
```

Due to unfortunate choices in the original API, the params used to populate the
query string are actually taken out of the headers hash. So if you want to pass
both the params hash and more complex options, use the special key
`:params` in the headers hash. This design may change in a future major
release.

```ruby
SimpleRestClient::Request.execute(method: :get, url: 'http://example.com/resource',
                            timeout: 10, headers: {params: {foo: 'bar'}})

➔ GET http://example.com/resource?foo=bar
```

## Multipart

Yeah, that's right!  This does multipart sends for you!

```ruby
SimpleRestClient.post '/data', :myfile => File.new("/path/to/image.jpg", 'rb')
```

This does two things for you:

- Auto-detects that you have a File value sends it as multipart
- Auto-detects the mime of the file and sets it in the HEAD of the payload for each entry

If you are sending params that do not contain a File object but the payload needs to be multipart then:

```ruby
SimpleRestClient.post '/data', {:foo => 'bar', :multipart => true}
```

## Usage: ActiveResource-Style

```ruby
resource = SimpleRestClient::Resource.new 'http://example.com/resource'
resource.get

private_resource = SimpleRestClient::Resource.new 'https://example.com/private/resource', 'user', 'pass'
private_resource.put File.read('pic.jpg'), :content_type => 'image/jpg'
```

See SimpleRestClient::Resource module docs for details.

## Usage: Resource Nesting

```ruby
site = SimpleRestClient::Resource.new('http://example.com')
site['posts/1/comments'].post 'Good article.', :content_type => 'text/plain'
```
See `SimpleRestClient::Resource` docs for details.

## Exceptions (see http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html)

- for result codes between `200` and `207`, a `SimpleRestClient::Response` will be returned
- for result codes `301`, `302` or `307`, the redirection will be followed if the request is a `GET` or a `HEAD`
- for result code `303`, the redirection will be followed and the request transformed into a `GET`
- for other cases, a `SimpleRestClient::ExceptionWithResponse` holding the Response will be raised; a specific exception class will be thrown for known error codes
- call `.response` on the exception to get the server's response

```ruby
>> SimpleRestClient.get 'http://example.com/nonexistent'
Exception: SimpleRestClient::NotFound: 404 Not Found

>> begin
     SimpleRestClient.get 'http://example.com/nonexistent'
   rescue SimpleRestClient::ExceptionWithResponse => e
     e.response
   end
=> <SimpleRestClient::Response 404 "<!doctype h...">
```

### Other exceptions

While most exceptions have been collected under `SimpleRestClient::RequestFailed` aka
`SimpleRestClient::ExceptionWithResponse`, there are a few quirky exceptions that
have been kept for backwards compatibility.

SimpleRestClient will propagate up exceptions like socket errors without modification:

```ruby
>> SimpleRestClient.get 'http://localhost:12345'
Exception: Errno::ECONNREFUSED: Connection refused - connect(2) for "localhost" port 12345
```

SimpleRestClient handles a few specific error cases separately in order to give
better error messages. These will hopefully be cleaned up in a future major
release.

`SimpleRestClient::ServerBrokeConnection` is translated from `EOFError` to give a
better error message.

`SimpleRestClient::SSLCertificateNotVerified` is raised when HTTPS validation fails.
Other `OpenSSL::SSL::SSLError` errors are raised as is.

### Redirection

By default, simple-rest-client will follow HTTP 30x redirection requests.

__New in 2.0:__ `SimpleRestClient::Response` exposes a `#history` method that returns
a list of each response received in a redirection chain.

```ruby
>> r = SimpleRestClient.get('http://httpbin.org/redirect/2')
=> <SimpleRestClient::Response 200 "{\n  \"args\":...">

# see each response in the redirect chain
>> r.history
=> [<SimpleRestClient::Response 302 "<!DOCTYPE H...">, <SimpleRestClient::Response 302 "">]

# see each requested URL
>> r.request.url
=> "http://httpbin.org/get"
>> r.history.map {|x| x.request.url}
=> ["http://httpbin.org/redirect/2", "http://httpbin.org/relative-redirect/1"]
```

#### Manually following redirection

To disable automatic redirection, set `:max_redirects => 0`.

__New in 2.0:__ Prior versions of simple-rest-client would raise
`SimpleRestClient::MaxRedirectsReached`, with no easy way to access the server's
response. In 2.0, simple-rest-client raises the normal
`SimpleRestClient::ExceptionWithResponse` as it would with any other non-HTTP-20x
response.

```ruby
>> SimpleRestClient::Request.execute(method: :get, url: 'http://httpbin.org/redirect/1')
=> SimpleRestClient::Response 200 "{\n  "args":..."

>> SimpleRestClient::Request.execute(method: :get, url: 'http://httpbin.org/redirect/1', max_redirects: 0)
SimpleRestClient::Found: 302 Found
```

To manually follow redirection, you can call `Response#follow_redirection`. Or
you could of course inspect the result and choose custom behavior.

```ruby
>> SimpleRestClient::Request.execute(method: :get, url: 'http://httpbin.org/redirect/1', max_redirects: 0)
SimpleRestClient::Found: 302 Found
>> begin
       SimpleRestClient::Request.execute(method: :get, url: 'http://httpbin.org/redirect/1', max_redirects: 0)
   rescue SimpleRestClient::ExceptionWithResponse => err
   end
>> err
=> #<SimpleRestClient::Found: 302 Found>
>> err.response
=> SimpleRestClient::Response 302 "<!DOCTYPE H..."
>> err.response.headers[:location]
=> "/get"
>> err.response.follow_redirection
=> SimpleRestClient::Response 200 "{\n  "args":..."
```

## Result handling

The result of a `SimpleRestClient::Request` is a `SimpleRestClient::Response` object.

`SimpleRestClient::Response` objects are a subclass of `String`.

Response objects have several useful methods. (See the class rdoc for more details.)

- `Response#code`: The HTTP response code
- `Response#body`: The response body as a string. (AKA .to_s)
- `Response#headers`: A hash of HTTP response headers
- `Response#raw_headers`: A hash of HTTP response headers as unprocessed arrays
- `Response#cookies`: A hash of HTTP cookies set by the server
- `Response#cookie_jar`: <em>New in 1.8</em> An HTTP::CookieJar of cookies
- `Response#request`: The SimpleRestClient::Request object used to make the request
- `Response#history`: <em>New in 2.0</em> If redirection was followed, a list of prior Response objects

```ruby
SimpleRestClient.get('http://example.com')
➔ <SimpleRestClient::Response 200 "<!doctype h...">

begin
 SimpleRestClient.get('http://example.com/notfound')
rescue SimpleRestClient::ExceptionWithResponse => err
  err.response
end
➔ <SimpleRestClient::Response 404 "<!doctype h...">
```

### Response callbacks, error handling

A block can be passed to the SimpleRestClient method. This block will then be called with the Response.
Response.return! can be called to invoke the default response's behavior.

```ruby
# Don't raise exceptions but return the response
>> SimpleRestClient.get('http://example.com/nonexistent') {|response, request, result| response }
=> <SimpleRestClient::Response 404 "<!doctype h...">
```

```ruby
# Manage a specific error code
SimpleRestClient.get('http://example.com/resource') { |response, request, result, &block|
  case response.code
  when 200
    p "It worked !"
    response
  when 423
    raise SomeCustomExceptionIfYouWant
  else
    response.return!(&block)
  end
}
```

But note that it may be more straightforward to use exceptions to handle
different HTTP error response cases:

```ruby
begin
  resp = SimpleRestClient.get('http://example.com/resource')
rescue SimpleRestClient::Unauthorized, SimpleRestClient::Forbidden => err
  puts 'Access denied'
  return err.response
rescue SimpleRestClient::ImATeapot => err
  puts 'The server is a teapot! # RFC 2324'
  return err.response
else
  puts 'It worked!'
  return resp
end
```

For GET and HEAD requests, simple-rest-client automatically follows redirection. For
other HTTP verbs, call `.follow_redirection` on the response object (works both
in block form and in exception form).

```ruby
# Follow redirections for all request types and not only for get and head
# RFC : "If the 301, 302 or 307 status code is received in response to a request other than GET or HEAD,
#        the user agent MUST NOT automatically redirect the request unless it can be confirmed by the user,
#        since this might change the conditions under which the request was issued."

# block style
SimpleRestClient.post('http://example.com/redirect', 'body') { |response, request, result|
  case response.code
  when 301, 302, 307
    response.follow_redirection
  else
    response.return!
  end
}

# exception style by explicit classes
begin
  SimpleRestClient.post('http://example.com/redirect', 'body')
rescue SimpleRestClient::MovedPermanently,
       SimpleRestClient::Found,
       SimpleRestClient::TemporaryRedirect => err
  err.response.follow_redirection
end

# exception style by response code
begin
  SimpleRestClient.post('http://example.com/redirect', 'body')
rescue SimpleRestClient::ExceptionWithResponse => err
  case err.http_code
  when 301, 302, 307
    err.response.follow_redirection
  else
    raise
  end
end
```

## Non-normalized URIs

If you need to normalize URIs, e.g. to work with International Resource Identifiers (IRIs),
use the Addressable gem (https://github.com/sporkmonger/addressable/) in your code:

```ruby
  require 'addressable/uri'
  SimpleRestClient.get(Addressable::URI.parse("http://www.詹姆斯.com/").normalize.to_str)
```

## Lower-level access

For cases not covered by the general API, you can use the `SimpleRestClient::Request` class, which provides a lower-level API.

You can:

- specify ssl parameters
- override cookies
- manually handle the response (e.g. to operate on it as a stream rather than reading it all into memory)

See `SimpleRestClient::Request`'s documentation for more information.

### Streaming request payload

SimpleRestClient will try to stream any file-like payload rather than reading it into
memory. This happens through `SimpleRestClient::Payload::Streamed`, which is
automatically called internally by `SimpleRestClient::Payload.generate` on anything
with a `read` method.

```ruby
>> r = SimpleRestClient.put('http://httpbin.org/put', File.open('/tmp/foo.txt', 'r'),
                      content_type: 'text/plain')
=> <SimpleRestClient::Response 200 "{\n  \"args\":...">
```

In Multipart requests, SimpleRestClient will also stream file handles passed as Hash
(or ParamsArray).

```ruby
>> r = SimpleRestClient.put('http://httpbin.org/put',
                      {file_a: File.open('a.txt', 'r'),
                       file_b: File.open('b.txt', 'r')})
=> <SimpleRestClient::Response 200 "{\n  \"args\":...">

# received by server as two file uploads with multipart/form-data
>> JSON.parse(r)['files'].keys
=> ['file_a', 'file_b']
```

### Streaming responses

Normally, when you use `SimpleRestClient.get` or the lower level
`SimpleRestClient::Request.execute method: :get` to retrieve data, the entire
response is buffered in memory and returned as the response to the call.

However, if you are retrieving a large amount of data, for example a Docker
image, an iso, or any other large file, you may want to stream the response
directly to disk rather than loading it in memory. If you have a very large
file, it may become *impossible* to load it into memory.

There are two main ways to do this:

#### `raw_response`, saves into Tempfile

If you pass `raw_response: true` to `SimpleRestClient::Request.execute`, it will save
the response body to a temporary file (using `Tempfile`) and return a
`SimpleRestClient::RawResponse` object rather than a `SimpleRestClient::Response`.

Note that the tempfile created by `Tempfile.new` will be in `Dir.tmpdir`
(usually `/tmp/`), which you can override to store temporary files in a
different location. This file will be unlinked when it is dereferenced.

If logging is enabled, this will also print download progress.
Customize the interval with `:stream_log_percent` (defaults to
10 for printing a message every 10% complete).

For example:

```ruby
>> raw = SimpleRestClient::Request.execute(
           method: :get,
           url: 'http://releases.ubuntu.com/16.04.2/ubuntu-16.04.2-desktop-amd64.iso',
           raw_response: true)
=> <SimpleRestClient::RawResponse @code=200, @file=#<Tempfile:/tmp/simple-rest-client.20170522-5346-1pptjm1>, @request=<SimpleRestClient::Request @method="get", @url="http://releases.ubuntu.com/16.04.2/ubuntu-16.04.2-desktop-amd64.iso">>
>> raw.file.size
=> 1554186240
>> raw.file.path
=> "/tmp/simple-rest-client.20170522-5346-1pptjm1"
raw.file.path
=> "/tmp/simple-rest-client.20170522-5346-1pptjm1"

>> require 'digest/sha1'
>> Digest::SHA1.file(raw.file.path).hexdigest
=> "4375b73e3a1aa305a36320ffd7484682922262b3"
```

#### `block_response`, receives raw Net::HTTPResponse

If you want to stream the data from the response to a file as it comes, rather
than entirely in memory, you can also pass `SimpleRestClient::Request.execute` a
parameter `:block_response` to which you pass a block/proc. This block receives
the raw unmodified Net::HTTPResponse object from Net::HTTP, which you can use
to stream directly to a file as each chunk is received.

Note that this bypasses all the usual HTTP status code handling, so you will
want to do you own checking for HTTP 20x response codes, redirects, etc.

The following is an example:

````ruby
File.open('/some/output/file', 'w') {|f|
  block = proc { |response|
    response.read_body do |chunk|
      f.write chunk
    end
  }
  SimpleRestClient::Request.execute(method: :get,
                              url: 'http://example.com/some/really/big/file.img',
                              block_response: block)
}
````

## Shell

The simplerestclient shell command gives an IRB session with SimpleRestClient already loaded:

```ruby
$ simplerestclient
>> SimpleRestClient.get 'http://example.com'
```

Specify a URL argument for get/post/put/delete on that resource:

```ruby
$ simplerestclient http://example.com
>> put '/resource', 'data'
```

Add a user and password for authenticated resources:

```ruby
$ simplerestclient https://example.com user pass
>> delete '/private/resource'
```

Create ~/.simplerestclient for named sessions:

```ruby
  sinatra:
    url: http://localhost:4567
  rack:
    url: http://localhost:9292
  private_site:
    url: http://example.com
    username: user
    password: pass
```

Then invoke:

```ruby
$ simplerestclient private_site
```

Use as a one-off, curl-style:

```ruby
$ simplerestclient get http://example.com/resource > output_body

$ simplerestclient put http://example.com/resource < input_body
```

## Logging

To enable logging globally you can:

- set SimpleRestClient.log with a Ruby Logger

```ruby
SimpleRestClient.log = STDOUT
```

- or set an environment variable to avoid modifying the code (in this case you can use a file name, "stdout" or "stderr"):

```ruby
$ RESTCLIENT_LOG=stdout path/to/my/program
```

You can also set individual loggers when instantiating a Resource or making an
individual request:

```ruby
resource = SimpleRestClient::Resource.new 'http://example.com/resource', log: Logger.new(STDOUT)
```

```ruby
SimpleRestClient::Request.execute(method: :get, url: 'http://example.com/foo', log: Logger.new(STDERR))
```

All options produce logs like this:

```ruby
SimpleRestClient.get "http://some/resource"
# => 200 OK | text/html 250 bytes
SimpleRestClient.put "http://some/resource", "payload"
# => 401 Unauthorized | application/xml 340 bytes
```

Note that these logs are valid Ruby, so you can paste them into the `simplerestclient`
shell or a script to replay your sequence of rest calls.

## Proxy

All calls to SimpleRestClient, including Resources, will use the proxy specified by
`SimpleRestClient.proxy`:

```ruby
SimpleRestClient.proxy = "http://proxy.example.com/"
SimpleRestClient.get "http://some/resource"
# => response from some/resource as proxied through proxy.example.com
```

Often the proxy URL is set in an environment variable, so you can do this to
use whatever proxy the system is configured to use:

```ruby
  SimpleRestClient.proxy = ENV['http_proxy']
```

__New in 2.0:__ Specify a per-request proxy by passing the :proxy option to
SimpleRestClient::Request. This will override any proxies set by environment variable
or by the global `SimpleRestClient.proxy` value.

```ruby
SimpleRestClient::Request.execute(method: :get, url: 'http://example.com',
                            proxy: 'http://proxy.example.com')
# => single request proxied through the proxy
```

This can be used to disable the use of a proxy for a particular request.

```ruby
SimpleRestClient.proxy = "http://proxy.example.com/"
SimpleRestClient::Request.execute(method: :get, url: 'http://example.com', proxy: nil)
# => single request sent without a proxy
```

## Query parameters

Rest-client can render a hash as HTTP query parameters for GET/HEAD/DELETE
requests or as HTTP post data in `x-www-form-urlencoded` format for POST
requests.

Even though there is no standard specifying how this should
work, simple-rest-client follows a similar convention to the one used by Rack / Rails
servers for handling arrays, nested hashes, and null values.

The implementation in
[./lib/simple-rest-client/utils.rb](SimpleRestClient::Utils.encode_query_string)
closely follows
[Rack::Utils.build_nested_query](http://www.rubydoc.info/gems/rack/Rack/Utils#build_nested_query-class_method),
but treats empty arrays and hashes as `nil`. (Rack drops them entirely, which
is confusing behavior.)

If you don't like this behavior and want more control, just serialize params
yourself (e.g. with `URI.encode_www_form`) and add the query string to the URL
directly for GET parameters or pass the payload as a string for POST requests.

Basic GET params:
```ruby
SimpleRestClient.get('https://httpbin.org/get', params: {foo: 'bar', baz: 'qux'})
# GET "https://httpbin.org/get?foo=bar&baz=qux"
```

Basic `x-www-form-urlencoded` POST params:
```ruby
>> r = SimpleRestClient.post('https://httpbin.org/post', {foo: 'bar', baz: 'qux'})
# POST "https://httpbin.org/post", data: "foo=bar&baz=qux"
=> <SimpleRestClient::Response 200 "{\n  \"args\":...">
>> JSON.parse(r.body)
=> {"args"=>{},
    "data"=>"",
    "files"=>{},
    "form"=>{"baz"=>"qux", "foo"=>"bar"},
    "headers"=>
    {"Accept"=>"*/*",
        "Accept-Encoding"=>"gzip, deflate",
        "Content-Length"=>"15",
        "Content-Type"=>"application/x-www-form-urlencoded",
        "Host"=>"httpbin.org"},
    "json"=>nil,
    "url"=>"https://httpbin.org/post"}
```

JSON payload: simple-rest-client does not speak JSON natively, so serialize your
payload to a string before passing it to simple-rest-client.
```ruby
>> payload = {'name' => 'newrepo', 'description': 'A new repo'}
>> SimpleRestClient.post('https://api.github.com/user/repos', payload.to_json, content_type: :json)
=> <SimpleRestClient::Response 201 "{\"id\":75149...">
```

Advanced GET params (arrays):
```ruby
>> r = SimpleRestClient.get('https://http-params.herokuapp.com/get', params: {foo: [1,2,3]})
# GET "https://http-params.herokuapp.com/get?foo[]=1&foo[]=2&foo[]=3"
=> <SimpleRestClient::Response 200 "Method: GET...">
>> puts r.body
query_string: "foo[]=1&foo[]=2&foo[]=3"
decoded:      "foo[]=1&foo[]=2&foo[]=3"

GET:
  {"foo"=>["1", "2", "3"]}
```

Advanced GET params (nested hashes):
```ruby
>> r = SimpleRestClient.get('https://http-params.herokuapp.com/get', params: {outer: {foo: 123, bar: 456}})
# GET "https://http-params.herokuapp.com/get?outer[foo]=123&outer[bar]=456"
=> <SimpleRestClient::Response 200 "Method: GET...">
>> puts r.body
...
query_string: "outer[foo]=123&outer[bar]=456"
decoded:      "outer[foo]=123&outer[bar]=456"

GET:
  {"outer"=>{"foo"=>"123", "bar"=>"456"}}
```

__New in 2.0:__ The new `SimpleRestClient::ParamsArray` class allows callers to
provide ordering even to structured parameters. This is useful for unusual
cases where the server treats the order of parameters as significant or you
want to pass a particular key multiple times.

Multiple fields with the same name using ParamsArray:
```ruby
>> SimpleRestClient.get('https://httpbin.org/get', params:
                  SimpleRestClient::ParamsArray.new([[:foo, 1], [:foo, 2]]))
# GET "https://httpbin.org/get?foo=1&foo=2"
```

Nested ParamsArray:
```ruby
>> SimpleRestClient.get('https://httpbin.org/get', params:
                  {foo: SimpleRestClient::ParamsArray.new([[:a, 1], [:a, 2]])})
# GET "https://httpbin.org/get?foo[a]=1&foo[a]=2"
```

## Headers

Request headers can be set by passing a ruby hash containing keys and values
representing header names and values:

```ruby
# GET request with modified headers
SimpleRestClient.get 'http://example.com/resource', {:Authorization => 'Bearer cT0febFoD5lxAlNAXHo6g'}

# POST request with modified headers
SimpleRestClient.post 'http://example.com/resource', {:foo => 'bar', :baz => 'qux'}, {:Authorization => 'Bearer cT0febFoD5lxAlNAXHo6g'}

# DELETE request with modified headers
SimpleRestClient.delete 'http://example.com/resource', {:Authorization => 'Bearer cT0febFoD5lxAlNAXHo6g'}
```

## Timeouts

By default the timeout for a request is 60 seconds. Timeouts for your request can
be adjusted by setting the `timeout:` to the number of seconds that you would like
the request to wait. Setting `timeout:` will override both `read_timeout:` and `open_timeout:`.

```ruby
SimpleRestClient::Request.execute(method: :get, url: 'http://example.com/resource',
                            timeout: 120)
```

Additionally, you can set `read_timeout:` and `open_timeout:` separately.

```ruby
SimpleRestClient::Request.execute(method: :get, url: 'http://example.com/resource',
                            read_timeout: 120, open_timeout: 240)
```

## Cookies

Request and Response objects know about HTTP cookies, and will automatically
extract and set headers for them as needed:

```ruby
response = SimpleRestClient.get 'http://example.com/action_which_sets_session_id'
response.cookies
# => {"_applicatioN_session_id" => "1234"}

response2 = SimpleRestClient.post(
  'http://localhost:3000/',
  {:param1 => "foo"},
  {:cookies => {:session_id => "1234"}}
)
# ...response body
```
### Full cookie jar support (new in 1.8)

The original cookie implementation was very naive and ignored most of the
cookie RFC standards.
__New in 1.8__:  An HTTP::CookieJar of cookies

Response objects now carry a cookie_jar method that exposes an HTTP::CookieJar
of cookies, which supports full standards compliant behavior.

## SSL/TLS support

Various options are supported for configuring simple-rest-client's TLS settings. By
default, simple-rest-client will verify certificates using the system's CA store on
all platforms. (This is intended to be similar to how browsers behave.) You can
specify an :ssl_ca_file, :ssl_ca_path, or :ssl_cert_store to customize the
certificate authorities accepted.

### SSL Client Certificates

```ruby
SimpleRestClient::Resource.new(
  'https://example.com',
  :ssl_client_cert  =>  OpenSSL::X509::Certificate.new(File.read("cert.pem")),
  :ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read("key.pem"), "passphrase, if any"),
  :ssl_ca_file      =>  "ca_certificate.pem",
  :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
).get
```
Self-signed certificates can be generated with the openssl command-line tool.

## Hook

SimpleRestClient.add_before_execution_proc add a Proc to be called before each execution.
It's handy if you need direct access to the HTTP request.

Example:

```ruby
# Add oauth support using the oauth gem
require 'oauth'
access_token = ...

SimpleRestClient.add_before_execution_proc do |req, params|
  access_token.sign! req
end

SimpleRestClient.get 'http://example.com'
```

## Credits
| | |
|-------------------------|---------------------------------------------------------|
| **REST Client Team**    | Andy Brody                                              |
| **Creator**             | Adam Wiggins                                            |
| **Maintainers Emeriti** | Lawrence Leonard Gilbert, Matthew Manning, Julien Kirch |
| **Major contributions** | Blake Mizerany, Julien Kirch                            |

A great many generous folks have contributed features and patches.
See AUTHORS for the full list.

## Legal

Released under the MIT License: https://opensource.org/licenses/MIT

Photo of the International Space Station was produced by NASA and is in the
public domain.

Code for reading Windows root certificate store derived from work by Puppet;
used under terms of the Apache License, Version 2.0.
