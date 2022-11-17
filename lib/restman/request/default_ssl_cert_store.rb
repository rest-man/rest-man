module RestMan
  class Request
    class DefaultSSLCertStore < ActiveMethod::Base

      def call
        cert_store = OpenSSL::X509::Store.new
        cert_store.set_default_paths

        # set_default_paths() doesn't do anything on Windows, so look up
        # certificates using the win32 API.
        if RestMan::Platform.windows?
          RestMan::Windows::RootCerts.instance.to_a.uniq.each do |cert|
            begin
              cert_store.add_cert(cert)
            rescue OpenSSL::X509::StoreError => err
              # ignore duplicate certs
              raise unless err.message == 'cert already in hash table'
            end
          end
        end

        cert_store
      end

    end
  end
end
