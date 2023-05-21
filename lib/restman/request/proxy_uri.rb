module RestMan
  class Request
    class ProxyURI < ActiveMethod::Base

      def call
        if request.instance_variable_defined?(:@proxy)
          if request.proxy
            URI.parse(request.proxy)
          else
            false
          end
        elsif RestMan.proxy_set?
          if RestMan.proxy
            URI.parse(RestMan.proxy)
          else
            false
          end
        else
          nil
        end
      end

      private

      def proxy
        request.proxy
      end

    end
  end
end