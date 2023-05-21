module RestMan
  class Request
    class Transmit < ActiveMethod::Base

      argument :uri
      argument :req
      argument :payload

      def call
        # We set this to true in the net/http block so that we can distinguish
        # read_timeout from open_timeout. Now that we only support Ruby 2.0+,
        # this is only needed for Timeout exceptions thrown outside of Net::HTTP.
        established_connection = false

        request.setup_credentials req

        net = request.net_http_object(uri.hostname, uri.port)
        net.use_ssl = uri.is_a?(URI::HTTPS)
        net.ssl_version = request.ssl_version if request.ssl_version
        net.min_version = request.ssl_min_version if request.ssl_min_version
        net.max_version = request.ssl_max_version if request.ssl_max_version
        net.ssl_timeout = request.ssl_timeout if request.ssl_timeout
        net.ciphers = request.ssl_ciphers if request.ssl_ciphers

        net.verify_mode = request.verify_ssl

        net.cert = request.ssl_client_cert if request.ssl_client_cert
        net.key = request.ssl_client_key if request.ssl_client_key
        net.ca_file = request.ssl_ca_file if request.ssl_ca_file
        net.ca_path = request.ssl_ca_path if request.ssl_ca_path
        net.cert_store = request.ssl_cert_store if request.ssl_cert_store

        net.max_retries = request.max_retries

        net.keep_alive_timeout = request.keep_alive_timeout if request.keep_alive_timeout
        net.close_on_empty_response = request.close_on_empty_response if request.close_on_empty_response
        net.local_host = request.local_host if request.local_host
        net.local_port = request.local_port if request.local_port

        # We no longer rely on net.verify_callback for the main SSL verification
        # because it's not well supported on all platforms (see comments below).
        # But do allow users to set one if they want.
        if request.ssl_verify_callback
          net.verify_callback = request.ssl_verify_callback

          # Hilariously, jruby only calls the callback when cert_store is set to
          # something, so make sure to set one.
          # https://github.com/jruby/jruby/issues/597
          if RestMan::Platform.jruby?
            net.cert_store ||= OpenSSL::X509::Store.new
          end

          if request.ssl_verify_callback_warnings != false
            if print_verify_callback_warnings
              warn('pass :ssl_verify_callback_warnings => false to silence this')
            end
          end
        end

        if OpenSSL::SSL::VERIFY_PEER == OpenSSL::SSL::VERIFY_NONE
          warn('WARNING: OpenSSL::SSL::VERIFY_PEER == OpenSSL::SSL::VERIFY_NONE')
          warn('This dangerous monkey patch leaves you open to MITM attacks!')
          warn('Try passing :verify_ssl => false instead.')
        end

        net.read_timeout = request.read_timeout
        net.open_timeout = request.open_timeout
        net.write_timeout = request.write_timeout

        RestMan.before_execution_procs.each do |before_proc|
          before_proc.call(req, request.args)
        end

        if request.before_execution_proc
          request.before_execution_proc.call(req, request.args)
        end

        request.log_request

        start_time = Time.now
        tempfile = nil

        net.start do |http|
          established_connection = true

          if request.block_response
            net_http_do_request(http, req, payload, &request.block_response)
          else
            res = net_http_do_request(http, req, payload) { |http_response|
              if request.raw_response
                # fetch body into tempfile
                tempfile = request.fetch_body_to_tempfile(http_response)
              else
                # fetch body
                http_response.read_body
              end
              http_response
            }
            if block_given?
              request.process_result(res, start_time, tempfile) do
                yield
              end
            else
              request.process_result(res, start_time, tempfile)
            end
          end
        end
      rescue EOFError
        raise RestMan::ServerBrokeConnection
      rescue Net::OpenTimeout => err
        raise RestMan::Exceptions::OpenTimeout.new(nil, err)
      rescue Net::ReadTimeout => err
        raise RestMan::Exceptions::ReadTimeout.new(nil, err)
      rescue Net::WriteTimeout => err
        raise RestMan::Exceptions::WriteTimeout.new(nil, err)
      rescue Timeout::Error, Errno::ETIMEDOUT => err
        # handling for non-Net::HTTP timeouts
        if established_connection
          raise RestMan::Exceptions::ReadTimeout.new(nil, err)
        else
          raise RestMan::Exceptions::OpenTimeout.new(nil, err)
        end
      end

      private

      def print_verify_callback_warnings
        warned = false
        if RestMan::Platform.mac_mri?
          warn('warning: ssl_verify_callback return code is ignored on OS X')
          warned = true
        end
        if RestMan::Platform.jruby?
          warn('warning: SSL verify_callback may not work correctly in jruby')
          warn('see https://github.com/jruby/jruby/issues/597')
          warned = true
        end
        warned
      end

      def net_http_do_request(http, req, body=nil, &block)
        if body && body.respond_to?(:read)
          req.body_stream = body
          return http.request(req, nil, &block)
        else
          return http.request(req, body, &block)
        end
      end

    end
  end
end
