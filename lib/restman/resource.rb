module RestMan
  # :include: _doc/lib/restman/resource.rdoc
  class Resource
    attr_reader :url, :options, :block

    def initialize(url, options={}, backwards_compatibility=nil, &block)
      @url = url
      @block = block
      if options.class == Hash
        @options = options
      else # compatibility with previous versions
        @options = { :user => options, :password => backwards_compatibility }
      end
    end

    def get(additional_headers={}, &block)
      headers = (options[:headers] || {}).merge(additional_headers)
      Request.execute(options.merge(
              :method => :get,
              :url => url,
              :headers => headers,
              :log => log), &(block || @block))
    end

    def head(additional_headers={}, &block)
      headers = (options[:headers] || {}).merge(additional_headers)
      Request.execute(options.merge(
              :method => :head,
              :url => url,
              :headers => headers,
              :log => log), &(block || @block))
    end

    def post(payload, additional_headers={}, &block)
      headers = (options[:headers] || {}).merge(additional_headers)
      Request.execute(options.merge(
              :method => :post,
              :url => url,
              :payload => payload,
              :headers => headers,
              :log => log), &(block || @block))
    end

    def put(payload, additional_headers={}, &block)
      headers = (options[:headers] || {}).merge(additional_headers)
      Request.execute(options.merge(
              :method => :put,
              :url => url,
              :payload => payload,
              :headers => headers,
              :log => log), &(block || @block))
    end

    def patch(payload, additional_headers={}, &block)
      headers = (options[:headers] || {}).merge(additional_headers)
      Request.execute(options.merge(
              :method => :patch,
              :url => url,
              :payload => payload,
              :headers => headers,
              :log => log), &(block || @block))
    end

    def delete(additional_headers={}, &block)
      headers = (options[:headers] || {}).merge(additional_headers)
      Request.execute(options.merge(
              :method => :delete,
              :url => url,
              :headers => headers,
              :log => log), &(block || @block))
    end

    def to_s
      url
    end

    def user
      options[:user]
    end

    def password
      options[:password]
    end

    def headers
      options[:headers] || {}
    end

    def read_timeout
      options[:read_timeout]
    end

    def open_timeout
      options[:open_timeout]
    end

    def log
      options[:log] || RestMan.log
    end

    # :include: _doc/lib/restman/resource/[].rdoc
    def [](suburl, &new_block)
      case
      when block_given? then self.class.new(concat_urls(url, suburl), options, &new_block)
      when block        then self.class.new(concat_urls(url, suburl), options, &block)
      else                   self.class.new(concat_urls(url, suburl), options)
      end
    end

    def concat_urls(url, suburl) # :nodoc:
      url = url.to_s
      suburl = suburl.to_s
      if url.slice(-1, 1) == '/' or suburl.slice(0, 1) == '/'
        url + suburl
      else
        "#{url}/#{suburl}"
      end
    end
  end
end
