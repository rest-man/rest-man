module RestMan
  class Request
    module Init
      class Url < ActiveMethod::Base

        autoload :AddQueryFromHeaders, "restman/request/init/url/add_query_from_headers"
        autoload :NormalizeUrl, "restman/request/init/url/normalize_url"

        argument :args
        argument :headers

        attr_accessor :url

        def call
          raise ArgumentError, "must pass :url" unless url

          add_http_scheme
          add_query_from_headers

          url
        end

        private

        def add_http_scheme
          self.url = NormalizeUrl.call(url)
        end

        def add_query_from_headers
          self.url = AddQueryFromHeaders.call(url, headers)
        end

        def url
          @url ||= args[:url].dup
        end

      end
    end
  end
end
