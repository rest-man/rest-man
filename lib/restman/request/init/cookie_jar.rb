module RestMan
  class Request
    module Init
      # :include: _doc/lib/restman/request/init/cookie_jar.rdoc
      class CookieJar < ActiveMethod::Base

        argument :uri
        argument :headers
        argument :args

        def call
          duplicated_cookies_check
          return cookies.dup if cookies.is_a?(HTTP::CookieJar)

          cookies.each do |key, value|
            cookie_jar.add cookie(key, value)
          end

          cookie_jar
        end

        private

        # Avoid ambiguity in whether options from headers or options from
        # Request#initialize should take precedence by raising ArgumentError when
        # both are present. Prior versions of rest-man claimed to give
        # precedence to init options, but actually gave precedence to headers.
        # Avoid that mess by erroring out instead.
        def duplicated_cookies_check
          if headers[:cookies] && args[:cookies]
            raise ArgumentError.new(
              "Cannot pass :cookies in Request.new() and in headers hash at the same time")
          end
        end

        def cookies
          @cookies ||= headers.delete(:cookies) || args[:cookies] || []
        end

        # Support for Array<HTTP::Cookie> mode:
        # If key is a cookie object, add it to the jar directly and assert that
        # there is no separate val.
        def cookie(key, value)
          if key.is_a?(HTTP::Cookie)
            raise ArgumentError.new("extra cookie val: #{value.inspect}") if value

            key # cookie
          else
            HTTP::Cookie.new(
              key.to_s, value,
              domain: uri.hostname.downcase,
              path: '/',
              for_domain: true
            )
          end
        end

        def cookie_jar
          @cookie_jar ||= HTTP::CookieJar.new
        end

      end
    end
  end
end
