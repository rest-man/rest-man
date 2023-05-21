module RestMan
  class Request
    class ProcessResult < ActiveMethod::Base

      argument :res
      argument :start_time 
      argument :tempfile, default: nil

      def call(&block)
        if raw_response
          unless tempfile
            raise ArgumentError.new('tempfile is required')
          end
          response = RawResponse.new(tempfile, res, request, start_time)
        else
          response = Response.create(res.body, res, request, start_time)
        end

        response.log_response

        if block_given?
          block.call(response, request, res, & block)
        else
          response.return!(&block)
        end
      end

      private

      def raw_response
        request.raw_response
      end

    end
  end
end
