require 'net/http'
require 'openssl'
require 'stringio'
require 'uri'
require 'active_method'

require File.dirname(__FILE__) + '/restman/version'
require File.dirname(__FILE__) + '/restman/statuses'
require File.dirname(__FILE__) + '/restman/platform'
require File.dirname(__FILE__) + '/restman/exceptions'
require File.dirname(__FILE__) + '/restman/utils'
require File.dirname(__FILE__) + '/restman/request'
require File.dirname(__FILE__) + '/restman/abstract_response'
require File.dirname(__FILE__) + '/restman/response'
require File.dirname(__FILE__) + '/restman/raw_response'
require File.dirname(__FILE__) + '/restman/resource'
require File.dirname(__FILE__) + '/restman/params_array'
require File.dirname(__FILE__) + '/restman/params_array/process_pair'
require File.dirname(__FILE__) + '/restman/payload'
require File.dirname(__FILE__) + '/restman/windows'

# :include: _doc/lib/restman.rdoc
module RestMan

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

  # :include: _doc/lib/restman/proxy.rdoc
  def self.proxy
    @proxy ||= nil
  end

  def self.proxy=(value)
    @proxy = value
    @proxy_set = true
  end

  # :include: _doc/lib/restman/proxy_set?.rdoc
  def self.proxy_set?
    @proxy_set ||= false
  end

  # :include: _doc/lib/restman/log=.rdoc
  def self.log= log
    @@log = create_log log
  end

  # :include: _doc/lib/restman/create_log.rdoc
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

  # :include: _doc/lib/restman/add_before_execution_proc.rdoc
  def self.add_before_execution_proc &proc
    raise ArgumentError.new('block is required') unless proc
    @@before_execution_procs << proc
  end

  # :include: _doc/lib/restman/reset_before_execution_procs.rdoc
  def self.reset_before_execution_procs
    @@before_execution_procs = []
  end

  def self.before_execution_procs # :nodoc:
    @@before_execution_procs
  end

end
