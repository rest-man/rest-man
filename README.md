# REST Man -- simple DSL for accessing HTTP and REST resources

[![CI](https://github.com/rest-man/rest-man/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/rest-man/rest-man/actions/workflows/ci.yml)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/f68e8752d2c740129b82394f973de025)](https://www.codacy.com/gh/rest-man/rest-man/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=rest-man/rest-man&amp;utm_campaign=Badge_Grade)
[![Codacy Badge](https://app.codacy.com/project/badge/Coverage/f68e8752d2c740129b82394f973de025)](https://www.codacy.com/gh/rest-man/rest-man/dashboard?utm_source=github.com&utm_medium=referral&utm_content=rest-man/rest-man&utm_campaign=Badge_Coverage)

A simple HTTP and REST client for Ruby, inspired by the Sinatra's microframework style
of specifying actions: get, put, post, delete.

This is a fork version of [rest-client](https://github.com/rest-client/rest-client)

## Requirements

Supported Ruby versions

| 2.6 | 2.7 | 3.0 | 3.1 | 3.2 | 3.3-Preview |
| ---- | ---- | ---- | ---- | ---- | ---- |
| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Supported JRuby versions

| 9.3 | 9.4 |
| ---- | ---- |
| ✅ | ✅ |

## Usage: Raw URL

Basic usage:

```ruby
require 'rest-man'

RestMan.get(url, headers={})

RestMan.post(url, payload, headers={})
```

In the high level helpers, only POST, PATCH, and PUT take a payload argument.
To pass a payload with other HTTP verbs or to pass more advanced options, use
`RestMan::Request.execute` instead.

More detailed examples:

```ruby
require 'rest-man'

RestMan.get 'http://example.com/resource'

RestMan.get 'http://example.com/resource', {params: {id: 50, 'foo' => 'bar'}}

RestMan.get 'https://user:password@example.com/private/resource', {accept: :json}

RestMan.post 'http://example.com/resource', {param1: 'one', nested: {param2: 'two'}}

RestMan.post "http://example.com/resource", {'x' => 1}.to_json, {content_type: :json, accept: :json}

RestMan.delete 'http://example.com/resource'

>> response = RestMan.get 'http://example.com/resource'
=> <RestMan::Response 200 "<!doctype h...">
>> response.code
=> 200
>> response.cookies
=> {"Foo"=>"BAR", "QUUX"=>"QUUUUX"}
>> response.headers
=> {:content_type=>"text/html; charset=utf-8", :cache_control=>"private" ... }
>> response.body
=> "<!doctype html>\n<html>\n<head>\n    <title>Example Domain</title>\n\n ..."

RestMan.post( url,
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

The top level helper methods like RestMan.get accept a headers hash as
their last argument and don't allow passing more complex options. But these
helpers are just thin wrappers around `RestMan::Request.execute`.

```ruby
RestMan::Request.execute(method: :get, url: 'http://example.com/resource',
                            timeout: 10)

RestMan::Request.execute(method: :get, url: 'http://example.com/resource',
                            ssl_ca_file: 'myca.pem',
                            ssl_ciphers: 'AESGCM:!aNULL')
```
You can also use this to pass a payload for HTTP verbs like DELETE, where the
`RestMan.delete` helper doesn't accept a payload.

```ruby
RestMan::Request.execute(method: :delete, url: 'http://example.com/resource',
                            payload: 'foo', headers: {myheader: 'bar'})
```

Due to unfortunate choices in the original API, the params used to populate the
query string are actually taken out of the headers hash. So if you want to pass
both the params hash and more complex options, use the special key
`:params` in the headers hash. This design may change in a future major
release.

```ruby
RestMan::Request.execute(method: :get, url: 'http://example.com/resource',
                            timeout: 10, headers: {params: {foo: 'bar'}})

➔ GET http://example.com/resource?foo=bar
```

## Multipart

Yeah, that's right!  This does multipart sends for you!

```ruby
RestMan.post '/data', :myfile => File.new("/path/to/image.jpg", 'rb')
```

This does two things for you:

- Auto-detects that you have a File value sends it as multipart
- Auto-detects the mime of the file and sets it in the HEAD of the payload for each entry

If you are sending params that do not contain a File object but the payload needs to be multipart then:

```ruby
RestMan.post '/data', {:foo => 'bar', :multipart => true}
```

## Usage: ActiveResource-Style

```ruby
resource = RestMan::Resource.new 'http://example.com/resource'
resource.get

private_resource = RestMan::Resource.new 'https://example.com/private/resource', 'user', 'pass'
private_resource.put File.read('pic.jpg'), :content_type => 'image/jpg'
```

See RestMan::Resource module docs for details.

## Usage: Resource Nesting

```ruby
site = RestMan::Resource.new('http://example.com')
site['posts/1/comments'].post 'Good article.', :content_type => 'text/plain'
```
See `RestMan::Resource` docs for details.

## Exceptions (see http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html)

- for result codes between `200` and `207`, a `RestMan::Response` will be returned
- for result codes `301`, `302` or `307`, the redirection will be followed if the request is a `GET` or a `HEAD`
- for result code `303`, the redirection will be followed and the request transformed into a `GET`
- for other cases, a `RestMan::ExceptionWithResponse` holding the Response will be raised; a specific exception class will be thrown for known error codes
- call `.response` on the exception to get the server's response

```ruby
>> RestMan.get 'http://example.com/nonexistent'
Exception: RestMan::NotFound: 404 Not Found

>> begin
     RestMan.get 'http://example.com/nonexistent'
   rescue RestMan::ExceptionWithResponse => e
     e.response
   end
=> <RestMan::Response 404 "<!doctype h...">
```

### Other exceptions

While most exceptions have been collected under `RestMan::RequestFailed` aka
`RestMan::ExceptionWithResponse`, there are a few quirky exceptions that
have been kept for backwards compatibility.

RestMan will propagate up exceptions like socket errors without modification:

```ruby
>> RestMan.get 'http://localhost:12345'
Exception: Errno::ECONNREFUSED: Connection refused - connect(2) for "localhost" port 12345
```

RestMan handles a few specific error cases separately in order to give
better error messages. These will hopefully be cleaned up in a future major
release.

`RestMan::ServerBrokeConnection` is translated from `EOFError` to give a
better error message.

`RestMan::SSLCertificateNotVerified` is raised when HTTPS validation fails.
Other `OpenSSL::SSL::SSLError` errors are raised as is.

### Redirection

By default, rest-man will follow HTTP 30x redirection requests.

`RestMan::Response` exposes a `#history` method that returns
a list of each response received in a redirection chain.

```ruby
>> r = RestMan.get('http://httpbin.org/redirect/2')
=> <RestMan::Response 200 "{\n  \"args\":...">

# see each response in the redirect chain
>> r.history
=> [<RestMan::Response 302 "<!DOCTYPE H...">, <RestMan::Response 302 "">]

# see each requested URL
>> r.request.url
=> "http://httpbin.org/get"
>> r.history.map {|x| x.request.url}
=> ["http://httpbin.org/redirect/2", "http://httpbin.org/relative-redirect/1"]
```

#### Manually following redirection

To disable automatic redirection, set `:max_redirects => 0`.

```ruby
>> RestMan::Request.execute(method: :get, url: 'http://httpbin.org/redirect/1')
=> RestMan::Response 200 "{\n  "args":..."

>> RestMan::Request.execute(method: :get, url: 'http://httpbin.org/redirect/1', max_redirects: 0)
RestMan::Found: 302 Found
```

To manually follow redirection, you can call `Response#follow_redirection`. Or
you could of course inspect the result and choose custom behavior.

```ruby
>> RestMan::Request.execute(method: :get, url: 'http://httpbin.org/redirect/1', max_redirects: 0)
RestMan::Found: 302 Found
>> begin
       RestMan::Request.execute(method: :get, url: 'http://httpbin.org/redirect/1', max_redirects: 0)
   rescue RestMan::ExceptionWithResponse => err
   end
>> err
=> #<RestMan::Found: 302 Found>
>> err.response
=> RestMan::Response 302 "<!DOCTYPE H..."
>> err.response.headers[:location]
=> "/get"
>> err.response.follow_redirection
=> RestMan::Response 200 "{\n  "args":..."
```

#### Manually set max retries

The default max_retries is 1. You can change it to any number you like.

```ruby
RestMan::Request.execute(method: :get, url: 'http://httpbin.org', max_retires: 0)
```

## Result handling

The result of a `RestMan::Request` is a `RestMan::Response` object.

`RestMan::Response` objects are a subclass of `String`.

Response objects have several useful methods. (See the class rdoc for more details.)

- `Response#code`: The HTTP response code
- `Response#body`: The response body as a string. (AKA .to_s)
- `Response#headers`: A hash of HTTP response headers
- `Response#raw_headers`: A hash of HTTP response headers as unprocessed arrays
- `Response#cookies`: A hash of HTTP cookies set by the server
- `Response#cookie_jar`: An HTTP::CookieJar of cookies
- `Response#request`: The RestMan::Request object used to make the request
- `Response#history`: If redirection was followed, a list of prior Response objects

```ruby
RestMan.get('http://example.com')
➔ <RestMan::Response 200 "<!doctype h...">

begin
 RestMan.get('http://example.com/notfound')
rescue RestMan::ExceptionWithResponse => err
  err.response
end
➔ <RestMan::Response 404 "<!doctype h...">
```

### Response callbacks, error handling

A block can be passed to the RestMan method. This block will then be called with the Response.
Response.return! can be called to invoke the default response's behavior.

```ruby
# Don't raise exceptions but return the response
>> RestMan.get('http://example.com/nonexistent') {|response, request, result| response }
=> <RestMan::Response 404 "<!doctype h...">
```

```ruby
# Manage a specific error code
RestMan.get('http://example.com/resource') { |response, request, result, &block|
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
  resp = RestMan.get('http://example.com/resource')
rescue RestMan::Unauthorized, RestMan::Forbidden => err
  puts 'Access denied'
  return err.response
rescue RestMan::ImATeapot => err
  puts 'The server is a teapot! # RFC 2324'
  return err.response
else
  puts 'It worked!'
  return resp
end
```

For GET and HEAD requests, rest-man automatically follows redirection. For
other HTTP verbs, call `.follow_redirection` on the response object (works both
in block form and in exception form).

```ruby
# Follow redirections for all request types and not only for get and head
# RFC : "If the 301, 302 or 307 status code is received in response to a request other than GET or HEAD,
#        the user agent MUST NOT automatically redirect the request unless it can be confirmed by the user,
#        since this might change the conditions under which the request was issued."

# block style
RestMan.post('http://example.com/redirect', 'body') { |response, request, result|
  case response.code
  when 301, 302, 307
    response.follow_redirection
  else
    response.return!
  end
}

# exception style by explicit classes
begin
  RestMan.post('http://example.com/redirect', 'body')
rescue RestMan::MovedPermanently,
       RestMan::Found,
       RestMan::TemporaryRedirect => err
  err.response.follow_redirection
end

# exception style by response code
begin
  RestMan.post('http://example.com/redirect', 'body')
rescue RestMan::ExceptionWithResponse => err
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
  RestMan.get(Addressable::URI.parse("http://www.詹姆斯.com/").normalize.to_str)
```

## Lower-level access

For cases not covered by the general API, you can use the `RestMan::Request` class, which provides a lower-level API.

You can:

- specify ssl parameters
- override cookies
- manually handle the response (e.g. to operate on it as a stream rather than reading it all into memory)

See `RestMan::Request`'s documentation for more information.

### Streaming request payload

RestMan will try to stream any file-like payload rather than reading it into
memory. This happens through `RestMan::Payload::Streamed`, which is
automatically called internally by `RestMan::Payload.generate` on anything
with a `read` method.

```ruby
>> r = RestMan.put('http://httpbin.org/put', File.open('/tmp/foo.txt', 'r'),
                      content_type: 'text/plain')
=> <RestMan::Response 200 "{\n  \"args\":...">
```

In Multipart requests, RestMan will also stream file handles passed as Hash
(or ParamsArray).

```ruby
>> r = RestMan.put('http://httpbin.org/put',
                      {file_a: File.open('a.txt', 'r'),
                       file_b: File.open('b.txt', 'r')})
=> <RestMan::Response 200 "{\n  \"args\":...">

# received by server as two file uploads with multipart/form-data
>> JSON.parse(r)['files'].keys
=> ['file_a', 'file_b']
```

### Streaming responses

Normally, when you use `RestMan.get` or the lower level
`RestMan::Request.execute method: :get` to retrieve data, the entire
response is buffered in memory and returned as the response to the call.

However, if you are retrieving a large amount of data, for example a Docker
image, an iso, or any other large file, you may want to stream the response
directly to disk rather than loading it in memory. If you have a very large
file, it may become *impossible* to load it into memory.

There are two main ways to do this:

#### `raw_response`, saves into Tempfile

If you pass `raw_response: true` to `RestMan::Request.execute`, it will save
the response body to a temporary file (using `Tempfile`) and return a
`RestMan::RawResponse` object rather than a `RestMan::Response`.

Note that the tempfile created by `Tempfile.new` will be in `Dir.tmpdir`
(usually `/tmp/`), which you can override to store temporary files in a
different location. This file will be unlinked when it is dereferenced.

If logging is enabled, this will also print download progress.
Customize the interval with `:stream_log_percent` (defaults to
10 for printing a message every 10% complete).

For example:

```ruby
>> raw = RestMan::Request.execute(
           method: :get,
           url: 'http://releases.ubuntu.com/16.04.2/ubuntu-16.04.2-desktop-amd64.iso',
           raw_response: true)
=> <RestMan::RawResponse @code=200, @file=#<Tempfile:/tmp/rest-man.20170522-5346-1pptjm1>, @request=<RestMan::Request @method="get", @url="http://releases.ubuntu.com/16.04.2/ubuntu-16.04.2-desktop-amd64.iso">>
>> raw.file.size
=> 1554186240
>> raw.file.path
=> "/tmp/rest-man.20170522-5346-1pptjm1"
raw.file.path
=> "/tmp/rest-man.20170522-5346-1pptjm1"

>> require 'digest/sha1'
>> Digest::SHA1.file(raw.file.path).hexdigest
=> "4375b73e3a1aa305a36320ffd7484682922262b3"
```

#### `block_response`, receives raw Net::HTTPResponse

If you want to stream the data from the response to a file as it comes, rather
than entirely in memory, you can also pass `RestMan::Request.execute` a
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
  RestMan::Request.execute(method: :get,
                              url: 'http://example.com/some/really/big/file.img',
                              block_response: block)
}
````

## Shell

The restman shell command gives an IRB session with RestMan already loaded:

```ruby
$ restman
>> RestMan.get 'http://example.com'
```

Specify a URL argument for get/post/put/delete on that resource:

```ruby
$ restman http://example.com
>> put '/resource', 'data'
```

Add a user and password for authenticated resources:

```ruby
$ restman https://example.com user pass
>> delete '/private/resource'
```

Create ~/.restman for named sessions:

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
$ restman private_site
```

Use as a one-off, curl-style:

```ruby
$ restman get http://example.com/resource > output_body

$ restman put http://example.com/resource < input_body
```

## Logging

To enable logging globally you can:

- set RestMan.log with a Ruby Logger

```ruby
RestMan.log = STDOUT
```

- or set an environment variable to avoid modifying the code (in this case you can use a file name, "stdout" or "stderr"):

```ruby
$ RESTCLIENT_LOG=stdout path/to/my/program
```

You can also set individual loggers when instantiating a Resource or making an
individual request:

```ruby
resource = RestMan::Resource.new 'http://example.com/resource', log: Logger.new(STDOUT)
```

```ruby
RestMan::Request.execute(method: :get, url: 'http://example.com/foo', log: Logger.new(STDERR))
```

All options produce logs like this:

```ruby
RestMan.get "http://some/resource"
# => 200 OK | text/html 250 bytes
RestMan.put "http://some/resource", "payload"
# => 401 Unauthorized | application/xml 340 bytes
```

Note that these logs are valid Ruby, so you can paste them into the `restman`
shell or a script to replay your sequence of rest calls.

## Proxy

All calls to RestMan, including Resources, will use the proxy specified by
`RestMan.proxy`:

```ruby
RestMan.proxy = "http://proxy.example.com/"
RestMan.get "http://some/resource"
# => response from some/resource as proxied through proxy.example.com
```

Often the proxy URL is set in an environment variable, so you can do this to
use whatever proxy the system is configured to use:

```ruby
  RestMan.proxy = ENV['http_proxy']
```

Specify a per-request proxy by passing the :proxy option to
RestMan::Request. This will override any proxies set by environment variable
or by the global `RestMan.proxy` value.

```ruby
RestMan::Request.execute(method: :get, url: 'http://example.com',
                            proxy: 'http://proxy.example.com')
# => single request proxied through the proxy
```

This can be used to disable the use of a proxy for a particular request.

```ruby
RestMan.proxy = "http://proxy.example.com/"
RestMan::Request.execute(method: :get, url: 'http://example.com', proxy: nil)
# => single request sent without a proxy
```

## Query parameters

Rest-client can render a hash as HTTP query parameters for GET/HEAD/DELETE
requests or as HTTP post data in `x-www-form-urlencoded` format for POST
requests.

Even though there is no standard specifying how this should
work, rest-man follows a similar convention to the one used by Rack / Rails
servers for handling arrays, nested hashes, and null values.

The implementation in
[./lib/rest-man/utils.rb](RestMan::Utils.encode_query_string)
closely follows
[Rack::Utils.build_nested_query](http://www.rubydoc.info/gems/rack/Rack/Utils#build_nested_query-class_method),
but treats empty arrays and hashes as `nil`. (Rack drops them entirely, which
is confusing behavior.)

If you don't like this behavior and want more control, just serialize params
yourself (e.g. with `URI.encode_www_form`) and add the query string to the URL
directly for GET parameters or pass the payload as a string for POST requests.

Basic GET params:
```ruby
RestMan.get('https://httpbin.org/get', params: {foo: 'bar', baz: 'qux'})
# GET "https://httpbin.org/get?foo=bar&baz=qux"
```

Basic `x-www-form-urlencoded` POST params:
```ruby
>> r = RestMan.post('https://httpbin.org/post', {foo: 'bar', baz: 'qux'})
# POST "https://httpbin.org/post", data: "foo=bar&baz=qux"
=> <RestMan::Response 200 "{\n  \"args\":...">
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

JSON payload: rest-man does not speak JSON natively, so serialize your
payload to a string before passing it to rest-man.
```ruby
>> payload = {'name' => 'newrepo', 'description': 'A new repo'}
>> RestMan.post('https://api.github.com/user/repos', payload.to_json, content_type: :json)
=> <RestMan::Response 201 "{\"id\":75149...">
```

Advanced GET params (arrays):
```ruby
>> r = RestMan.get('https://http-params.herokuapp.com/get', params: {foo: [1,2,3]})
# GET "https://http-params.herokuapp.com/get?foo[]=1&foo[]=2&foo[]=3"
=> <RestMan::Response 200 "Method: GET...">
>> puts r.body
query_string: "foo[]=1&foo[]=2&foo[]=3"
decoded:      "foo[]=1&foo[]=2&foo[]=3"

GET:
  {"foo"=>["1", "2", "3"]}
```

Advanced GET params (nested hashes):
```ruby
>> r = RestMan.get('https://http-params.herokuapp.com/get', params: {outer: {foo: 123, bar: 456}})
# GET "https://http-params.herokuapp.com/get?outer[foo]=123&outer[bar]=456"
=> <RestMan::Response 200 "Method: GET...">
>> puts r.body
...
query_string: "outer[foo]=123&outer[bar]=456"
decoded:      "outer[foo]=123&outer[bar]=456"

GET:
  {"outer"=>{"foo"=>"123", "bar"=>"456"}}
```

The `RestMan::ParamsArray` class allows callers to
provide ordering even to structured parameters. This is useful for unusual
cases where the server treats the order of parameters as significant or you
want to pass a particular key multiple times.

Multiple fields with the same name using ParamsArray:
```ruby
>> RestMan.get('https://httpbin.org/get', params:
                  RestMan::ParamsArray.new([[:foo, 1], [:foo, 2]]))
# GET "https://httpbin.org/get?foo=1&foo=2"
```

Nested ParamsArray:
```ruby
>> RestMan.get('https://httpbin.org/get', params:
                  {foo: RestMan::ParamsArray.new([[:a, 1], [:a, 2]])})
# GET "https://httpbin.org/get?foo[a]=1&foo[a]=2"
```

## Headers

Request headers can be set by passing a ruby hash containing keys and values
representing header names and values:

```ruby
# GET request with modified headers
RestMan.get 'http://example.com/resource', {:Authorization => 'Bearer cT0febFoD5lxAlNAXHo6g'}

# POST request with modified headers
RestMan.post 'http://example.com/resource', {:foo => 'bar', :baz => 'qux'}, {:Authorization => 'Bearer cT0febFoD5lxAlNAXHo6g'}

# DELETE request with modified headers
RestMan.delete 'http://example.com/resource', {:Authorization => 'Bearer cT0febFoD5lxAlNAXHo6g'}
```

## Timeouts

By default the timeout for a request is 60 seconds. Timeouts for your request can
be adjusted by setting the `timeout:` to the number of seconds that you would like
the request to wait. Setting `timeout:` will override `read_timeout:`, `open_timeout:` and `write_timeout`.

```ruby
RestMan::Request.execute(method: :get, url: 'http://example.com/resource',
                            timeout: 120)
```

Additionally, you can set `read_timeout:`, `open_timeout:` and `write_timeout` separately.

```ruby
RestMan::Request.execute(method: :get, url: 'http://example.com/resource',
                            read_timeout: 120, open_timeout: 240, write_timeout: 120)
```

## Cookies

Request and Response objects know about HTTP cookies, and will automatically
extract and set headers for them as needed:

```ruby
response = RestMan.get 'http://example.com/action_which_sets_session_id'
response.cookies
# => {"_applicatioN_session_id" => "1234"}

response2 = RestMan.post(
  'http://localhost:3000/',
  {:param1 => "foo"},
  {:cookies => {:session_id => "1234"}}
)
# ...response body
```
### Full cookie jar support

Response objects carry a cookie_jar method that exposes an HTTP::CookieJar
of cookies, which supports full standards compliant behavior.

## SSL/TLS support

Various options are supported for configuring rest-man's TLS settings. By
default, rest-man will verify certificates using the system's CA store on
all platforms. (This is intended to be similar to how browsers behave.) You can
specify an :ssl_ca_file, :ssl_ca_path, or :ssl_cert_store to customize the
certificate authorities accepted.

### SSL Client Certificates

```ruby
RestMan::Resource.new(
  'https://example.com',
  :ssl_client_cert  =>  OpenSSL::X509::Certificate.new(File.read("cert.pem")),
  :ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read("key.pem"), "passphrase, if any"),
  :ssl_ca_file      =>  "ca_certificate.pem",
  :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
).get
```
Self-signed certificates can be generated with the openssl command-line tool.

## Hook

RestMan.add_before_execution_proc add a Proc to be called before each execution.
It's handy if you need direct access to the HTTP request.

Example:

```ruby
# Add oauth support using the oauth gem
require 'oauth'
access_token = ...

RestMan.add_before_execution_proc do |req, params|
  access_token.sign! req
end

RestMan.get 'http://example.com'
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
