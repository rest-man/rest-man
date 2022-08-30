module RestMan
  module Payload
    class Streamed < Base
      def build_stream(params = nil)
        @stream = params
      end

      def size
        if @stream.respond_to?(:size)
          @stream.size
        elsif @stream.is_a?(IO)
          @stream.stat.size
        end
      end

      # TODO (breaks compatibility): ought to use mime_for() to autodetect the
      # Content-Type for stream objects that have a filename.

      alias :length :size
    end
  end
end
