module RestMan
  class Request
    class DefaultSSLCertStore < ActiveMethod::Base

      def call
        cert_store = OpenSSL::X509::Store.new
        cert_store.set_default_paths
        cert_store
      end

    end
  end
end
