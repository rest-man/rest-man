require 'tempfile'
require 'securerandom'

module RestMan
  module Payload
    class Multipart < Base

      def build_stream(params)
        @stream = Tempfile.new('rest-man.multipart.')
        @stream.binmode
        flatten(params).each do |name, value|
          write_content_disposition(@stream, name, value, boundary)
        end
        @stream.write "--#{boundary}--\r\n"
        @stream.seek(0)
      end

      def flatten(params)
        case params
        when Hash, ParamsArray
          Utils.flatten_params(params)
        else
          params
        end
      end

      def write_content_disposition(stream, name, value, boundary)
        WriteContentDisposition.call(stream, name, value, boundary)
      end

      def boundary
        return @boundary if defined?(@boundary) && @boundary

        # Use the same algorithm used by WebKit: generate 16 random
        # alphanumeric characters, replacing `+` `/` with `A` `B` (included in
        # the list twice) to round out the set of 64.
        s = SecureRandom.base64(12)
        s.tr!('+/', 'AB')

        @boundary = '----RubyFormBoundary' + s
      end

      def headers
        super.merge({'Content-Type' => %Q{multipart/form-data; boundary=#{boundary}}})
      end

      def close
        @stream.close!
      end
    end
  end
end
