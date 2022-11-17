module RestMan
  class Request
    class MakeCookieHeader < ActiveMethod::Base

      def call
        return nil if request.cookie_jar.nil?

        arr = request.cookie_jar.cookies(request.url)
        return nil if arr.empty?

        return HTTP::Cookie.cookie_value(arr)
      end

    end
  end
end
