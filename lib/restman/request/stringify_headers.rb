module RestMan
  class Request
    class StringifyHeaders < ActiveMethod::Base

      argument :headers

      def call
        headers.inject({}) do |result, (key, value)|

          if key.is_a? Symbol
            key = key.to_s.split(/_/).map(&:capitalize).join('-')
          end

          if 'CONTENT-TYPE' == key.upcase
            result[key] = MaybeConvertExtension.call(value.to_s)
          elsif 'ACCEPT' == key.upcase
            # Accept can be composed of several comma-separated values
            if value.is_a? Array
              target_values = value
            else
              target_values = value.to_s.split ','
            end
            result[key] = target_values.map { |ext|
              MaybeConvertExtension.call(ext.to_s.strip)
            }.join(', ')
          else
            result[key] = value.to_s
          end

          result
        end
      end

    end
  end
end
