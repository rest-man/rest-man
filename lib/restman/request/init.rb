require 'cgi'
require 'netrc'

module RestMan
  class Request
    module Init

      autoload :Url, 'restman/request/init/url'
      autoload :CookieJar, 'restman/request/init/cookie_jar'

      include ActiveMethod

      module_function

      # :include: _doc/lib/restman/request/init/http_method.rdoc
      def http_method(args)
        method = args[:method]
        raise ArgumentError.new('must pass :method') unless method

        method.to_s.downcase
      end

      def headers(args)
        (args[:headers] || {}).dup
      end

      active_method :url, module_function: true

      def uri(url)
        uri = URI.parse(url)

        if uri.hostname.nil?
          raise URI::InvalidURIError.new("bad URI(no host provided): #{url}")
        end

        uri
      end

      def auth(uri, args)
        user = CGI.unescape(uri.user) if uri.user
        password = CGI.unescape(uri.password) if uri.password

        if !user && !password
          user, password = Netrc.read[uri.hostname]
        end

        user = args[:user] if args.include?(:user)
        password = args[:password] if args.include?(:password)

        [user, password]
      end

      active_method :cookie_jar, module_function: true

    end
  end
end