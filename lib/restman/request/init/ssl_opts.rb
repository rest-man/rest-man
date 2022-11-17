module RestMan
  class Request
    module Init
      class SSLOpts < ActiveMethod::Base

        argument :args
        argument :uri

        def call
          ssl_opts[:verify_ssl] = verify_ssl
 
          Request::SSLOptionList.each do |key|
            ssl_key = ('ssl_' + key).to_sym

            if args.key?(ssl_key)
              ssl_opts[key.to_sym] = args.fetch(ssl_key)
            end
          end
    
          set_cert_store

          ssl_opts
        end

        private

        def verify_ssl
          return default_ssl_verify unless args.key?(:verify_ssl)
          return ssl_verify_none unless args[:verify_ssl]

          if args[:verify_ssl] == true
            default_ssl_verify 
          else
            args[:verify_ssl]
          end
        end

        def default_ssl_verify
          ssl_verify_peer
        end

        def ssl_verify_peer
          OpenSSL::SSL::VERIFY_PEER
        end

        def ssl_verify_none
          OpenSSL::SSL::VERIFY_NONE
        end

        def set_cert_store
          return unless use_ssl?
    
          # If there's no CA file, CA path, or cert store provided, use default
          if !ssl_opts[:ca_file] && !ssl_opts[:ca_path] && !ssl_opts.include?(:cert_store)
            ssl_opts[:cert_store] = Request.default_ssl_cert_store
          end
        end

        def use_ssl?
          uri.is_a?(URI::HTTPS)
        end

        def ssl_opts
          @ssl_opts ||= {}
        end

      end
    end
  end
end
