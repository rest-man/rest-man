module RestMan
  class Request
    class MakeHeaders < ActiveMethod::Base

      argument :user_headers

      def call
        headers = StringifyHeaders.call(default_headers).merge(StringifyHeaders.call(user_headers))

        # override headers from the payload (e.g. Content-Type, Content-Length)
        if payload
          headers = payload.headers.merge(headers)
        end

        # merge in cookies
        cookies = request.make_cookie_header
        if cookies && !cookies.empty?
          if headers['Cookie']
            warn('warning: overriding "Cookie" header with :cookies option')
          end
          headers['Cookie'] = cookies
        end

        headers
      end

      private

      def default_headers
        request.default_headers
      end

      def payload
        request.payload
      end

    end
  end
end
