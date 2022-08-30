require 'tempfile'
require 'securerandom'

module RestMan
  module Payload
    class Multipart < Base
      EOL = "\r\n"

      def build_stream(params)
        b = '--' + boundary

        @stream = Tempfile.new('rest-man.multipart.')
        @stream.binmode
        @stream.write(b + EOL)

        case params
        when Hash, ParamsArray
          x = Utils.flatten_params(params)
        else
          x = params
        end

        last_index = x.length - 1
        x.each_with_index do |a, index|
          k, v = * a
          if v.respond_to?(:read) && v.respond_to?(:path)
            create_file_field(@stream, k, v)
          else
            create_regular_field(@stream, k, v)
          end
          @stream.write(EOL + b)
          @stream.write(EOL) unless last_index == index
        end
        @stream.write('--')
        @stream.write(EOL)
        @stream.seek(0)
      end

      def create_regular_field(s, k, v)
        s.write("Content-Disposition: form-data; name=\"#{k}\"")
        s.write(EOL)
        s.write(EOL)
        s.write(v)
      end

      def create_file_field(s, k, v)
        begin
          s.write("Content-Disposition: form-data;")
          s.write(" name=\"#{k}\";") unless (k.nil? || k=='')
          s.write(" filename=\"#{v.respond_to?(:original_filename) ? v.original_filename : File.basename(v.path)}\"#{EOL}")
          s.write("Content-Type: #{v.respond_to?(:content_type) ? v.content_type : mime_for(v.path)}#{EOL}")
          s.write(EOL)
          while (data = v.read(8124))
            s.write(data)
          end
        ensure
          v.close if v.respond_to?(:close)
        end
      end

      def mime_for(path)
        mime = MIME::Types.type_for path
        mime.empty? ? 'text/plain' : mime[0].content_type
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

      # :include: _doc/lib/restman/payload/handle_key.rdoc
      def handle_key key
        key
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
