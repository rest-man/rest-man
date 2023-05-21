module RestMan
  class Request
    class LogRequest < ActiveMethod::Base

      def call
        return unless log

        out = []

        out << "RestMan.#{request.method} #{redacted_url.inspect}"
        out << payload.short_inspect if payload
        out << request.processed_headers.to_a.sort.map { |(k, v)| [k.inspect, v.inspect].join("=>") }.join(", ")
        log << out.join(', ') + "\n"
      end

      private

      def log
        request.log
      end

      def redacted_uri
        if uri.password
          sanitized_uri = uri.dup
          sanitized_uri.password = 'REDACTED'
          sanitized_uri
        else
          uri
        end
      end

      def redacted_url
        redacted_uri.to_s
      end

      def payload
        request.payload
      end

      def uri
        request.uri
      end

    end
  end
end
