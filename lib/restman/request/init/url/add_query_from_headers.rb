module RestMan
  class Request
    module Init
      class Url
        class AddQueryFromHeaders < ActiveMethod::Base

          argument :url
          argument :headers

          def call
            url_params = params_from_headers

            if url_params && !url_params.empty?
              query_string = RestMan::Utils.encode_query_string(url_params)

              if url.include?('?')
                url + "&#{query_string}"
              else
                url + "?#{query_string}"
              end
            else
              url
            end
          end

          private

          def params_from_headers
            params = nil

            # find and extract/remove "params" key if the value is a Hash/ParamsArray
            headers.delete_if do |key, value|
              if key.to_s.downcase == 'params' && (value.is_a?(Hash) || value.is_a?(RestMan::ParamsArray))
                if params
                  raise ArgumentError.new("Multiple 'params' options passed")
                end
                params = value
                true
              else
                false
              end
            end

            params
          end

        end
      end
    end
  end
end