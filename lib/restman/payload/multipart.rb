require 'tempfile'
require 'securerandom'

module RestMan
  module Payload
    class Multipart < Base
      autoload :WriteContentDisposition, "#{File.dirname(__FILE__)}/multipart/write_content_disposition"

      include ActiveMethod

      active_method :write_content_disposition

      def headers
        super.merge({'Content-Type' => %Q{multipart/form-data; boundary=#{boundary}}})
      end

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

      def close
        @stream.close!
      end

      def boundary
        @boundary ||= generate_boundary
      end

      private

      # Use the same algorithm used by WebKit: generate 16 random
      # alphanumeric characters, replacing `+` `/` with `A` `B` (included in
      # the list twice) to round out the set of 64.
      def generate_boundary
        s = SecureRandom.base64(12).tr('+/', 'AB')

        '----RubyFormBoundary' + s
      end
    end
  end
end
