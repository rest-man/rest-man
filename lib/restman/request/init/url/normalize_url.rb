module RestMan
  class Request
    module Init
      class Url
        class NormalizeUrl < ActiveMethod::Base
          argument :url

          def call
            if url.match(%r{\A[a-z][a-z0-9+.-]*://}i)
              url
            else
              "http://#{url}"
            end
          end
        end
      end
    end
  end
end
