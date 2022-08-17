require 'net/http'
require 'openssl'
require 'stringio'
require 'uri'

require File.dirname(__FILE__) + '/simplerestclient/version'
require File.dirname(__FILE__) + '/simplerestclient/platform'
require File.dirname(__FILE__) + '/simplerestclient/exceptions'
require File.dirname(__FILE__) + '/simplerestclient/utils'
require File.dirname(__FILE__) + '/simplerestclient/request'
require File.dirname(__FILE__) + '/simplerestclient/abstract_response'
require File.dirname(__FILE__) + '/simplerestclient/response'
require File.dirname(__FILE__) + '/simplerestclient/raw_response'
require File.dirname(__FILE__) + '/simplerestclient/resource'
require File.dirname(__FILE__) + '/simplerestclient/params_array'
require File.dirname(__FILE__) + '/simplerestclient/payload'
require File.dirname(__FILE__) + '/simplerestclient/windows'

# This module's static methods are the entry point for using the REST client.
#
#   # GET
#   xml = SimpleRestClient.get 'http://example.com/resource'
#   jpg = SimpleRestClient.get 'http://example.com/resource', :accept => 'image/jpg'
#
#   # authentication and SSL
#   SimpleRestClient.get 'https://user:password@example.com/private/resource'
#
#   # POST or PUT with a hash sends parameters as a urlencoded form body
#   SimpleRestClient.post 'http://example.com/resource', :param1 => 'one'
#
#   # nest hash parameters
#   SimpleRestClient.post 'http://example.com/resource', :nested => { :param1 => 'one' }
#
#   # POST and PUT with raw payloads
#   SimpleRestClient.post 'http://example.com/resource', 'the post body', :content_type => 'text/plain'
#   SimpleRestClient.post 'http://example.com/resource.xml', xml_doc
#   SimpleRestClient.put 'http://example.com/resource.pdf', File.read('my.pdf'), :content_type => 'application/pdf'
#
#   # DELETE
#   SimpleRestClient.delete 'http://example.com/resource'
#
#   # retrieve the response http code and headers
#   res = SimpleRestClient.get 'http://example.com/some.jpg'
#   res.code                    # => 200
#   res.headers[:content_type]  # => 'image/jpg'
#
#   # HEAD
#   SimpleRestClient.head('http://example.com').headers
#
# To use with a proxy, just set SimpleRestClient.proxy to the proper http proxy:
#
#   SimpleRestClient.proxy = "http://proxy.example.com/"
#
# Or inherit the proxy from the environment:
#
#   SimpleRestClient.proxy = ENV['http_proxy']
#
# For live tests of SimpleRestClient, try using http://rest-test.heroku.com, which echoes back information about the rest call:
#
#   >> SimpleRestClient.put 'http://rest-test.heroku.com/resource', :foo => 'baz'
#   => "PUT http://rest-test.heroku.com/resource with a 7 byte payload, content type application/x-www-form-urlencoded {\"foo\"=>\"baz\"}"
#
module SimpleRestClient

  def self.get(url, headers={}, &block)
    Request.execute(:method => :get, :url => url, :headers => headers, &block)
  end

  def self.post(url, payload, headers={}, &block)
    Request.execute(:method => :post, :url => url, :payload => payload, :headers => headers, &block)
  end

  def self.patch(url, payload, headers={}, &block)
    Request.execute(:method => :patch, :url => url, :payload => payload, :headers => headers, &block)
  end

  def self.put(url, payload, headers={}, &block)
    Request.execute(:method => :put, :url => url, :payload => payload, :headers => headers, &block)
  end

  def self.delete(url, headers={}, &block)
    Request.execute(:method => :delete, :url => url, :headers => headers, &block)
  end

  def self.head(url, headers={}, &block)
    Request.execute(:method => :head, :url => url, :headers => headers, &block)
  end

  def self.options(url, headers={}, &block)
    Request.execute(:method => :options, :url => url, :headers => headers, &block)
  end

  # A global proxy URL to use for all requests. This can be overridden on a
  # per-request basis by passing `:proxy` to SimpleRestClient::Request.
  def self.proxy
    @proxy ||= nil
  end

  def self.proxy=(value)
    @proxy = value
    @proxy_set = true
  end

  # Return whether SimpleRestClient.proxy was set explicitly. We use this to
  # differentiate between no value being set and a value explicitly set to nil.
  #
  # @return [Boolean]
  #
  def self.proxy_set?
    @proxy_set ||= false
  end

  # Setup the log for SimpleRestClient calls.
  # Value should be a logger but can can be stdout, stderr, or a filename.
  # You can also configure logging by the environment variable RESTCLIENT_LOG.
  def self.log= log
    @@log = create_log log
  end

  # Create a log that respond to << like a logger
  # param can be 'stdout', 'stderr', a string (then we will log to that file) or a logger (then we return it)
  def self.create_log param
    if param
      if param.is_a? String
        if param == 'stdout'
          stdout_logger = Class.new do
            def << obj
              STDOUT.puts obj
            end
          end
          stdout_logger.new
        elsif param == 'stderr'
          stderr_logger = Class.new do
            def << obj
              STDERR.puts obj
            end
          end
          stderr_logger.new
        else
          file_logger = Class.new do
            attr_writer :target_file

            def << obj
              File.open(@target_file, 'a') { |f| f.puts obj }
            end
          end
          logger = file_logger.new
          logger.target_file = param
          logger
        end
      else
        param
      end
    end
  end

  @@env_log = create_log ENV['RESTCLIENT_LOG']

  @@log = nil

  def self.log # :nodoc:
    @@env_log || @@log
  end

  @@before_execution_procs = []

  # Add a Proc to be called before each request in executed.
  # The proc parameters will be the http request and the request params.
  def self.add_before_execution_proc &proc
    raise ArgumentError.new('block is required') unless proc
    @@before_execution_procs << proc
  end

  # Reset the procs to be called before each request is executed.
  def self.reset_before_execution_procs
    @@before_execution_procs = []
  end

  def self.before_execution_procs # :nodoc:
    @@before_execution_procs
  end

end
