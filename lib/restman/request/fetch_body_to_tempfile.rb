module RestMan
  class Request
    class FetchBodyToTempfile < ActiveMethod::Base

      argument :http_response

      def call
        # Taken from Chef, which as in turn...
        # Stolen from http://www.ruby-forum.com/topic/166423
        # Kudos to _why!
        tf = Tempfile.new('rest-man.')
        tf.binmode

        size = 0
        total = http_response['Content-Length'].to_i
        stream_log_bucket = nil

        http_response.read_body do |chunk|
          tf.write chunk
          size += chunk.size
          if log
            if total == 0
              log << "streaming %s %s (%d of unknown) [0 Content-Length]\n" % [method.upcase, url, size]
            else
              percent = (size * 100) / total
              current_log_bucket, _ = percent.divmod(stream_log_percent)
              if current_log_bucket != stream_log_bucket
                stream_log_bucket = current_log_bucket
                log << "streaming %s %s %d%% done (%d of %d)\n" % [method.upcase, url, (size * 100) / total, size, total]
              end
            end
          end
        end
        tf.close
        tf
      end

      private

      def log
        request.log
      end

      def method
        request.method
      end

      def url
        request.url
      end

      def stream_log_percent
        request.stream_log_percent
      end

    end
  end
end
