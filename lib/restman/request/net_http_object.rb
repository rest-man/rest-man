module RestMan
  class Request
    class NetHTTPObject < ActiveMethod::Base

      argument :hostname
      argument :port

      def call
        p_uri = request.proxy_uri

        if p_uri.nil?
          # no proxy set
          Net::HTTP.new(hostname, port)
        elsif !p_uri
          # proxy explicitly set to none
          Net::HTTP.new(hostname, port, nil, nil, nil, nil)
        else
          Net::HTTP.new(hostname, port,
                        p_uri.hostname, p_uri.port, p_uri.user, p_uri.password)
        end
      end

    end
  end
end
