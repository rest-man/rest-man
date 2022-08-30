module RestMan
  module Payload
    class UrlEncoded < Base
      def build_stream(params = nil)
        @stream = StringIO.new(Utils.encode_query_string(params))
        @stream.seek(0)
      end

      def headers
        super.merge({'Content-Type' => 'application/x-www-form-urlencoded'})
      end
    end
  end
end
