require 'stringio'

module RestMan
  module Payload
    class Base
      def initialize(params)
        build_stream(params)
      end

      def build_stream(params)
        @stream = StringIO.new(params)
        @stream.seek(0)
      end

      def read(*args)
        @stream.read(*args)
      end

      def to_s
        result = read
        @stream.seek(0)
        result
      end

      def headers
        {'Content-Length' => size.to_s}
      end

      def size
        @stream.size
      end

      alias :length :size

      def close
        @stream.close unless @stream.closed?
      end

      def closed?
        @stream.closed?
      end

      def to_s_inspect
        to_s.inspect
      end

      def short_inspect
        if size && size > 500
          "#{size} byte(s) length"
        else
          to_s_inspect
        end
      end

    end
  end
end
