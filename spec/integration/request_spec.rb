require_relative '_lib'

describe RestMan::Request do

  describe "ssl verification" do
    it "is successful with the correct ca_file" do
      VCR.use_cassette('request_mozilla_org') do
        request = RestMan::Request.new(
          :method => :get,
          :url => 'https://www.mozilla.org',
          :ssl_ca_file => File.join(File.dirname(__FILE__), "certs", "digicert.crt")
        )
        expect { request.execute }.to_not raise_error
      end
    end

    it "is successful with the correct ca_path" do
      VCR.use_cassette('request_mozilla_org') do
        request = RestMan::Request.new(
          :method => :get,
          :url => 'https://www.mozilla.org',
          :ssl_ca_path => File.join(File.dirname(__FILE__), "capath_digicert")
        )
        expect { request.execute }.to_not raise_error
      end
    end

    it "is unsuccessful with an incorrect ca_file", :unless => RestMan::Platform.mac_mri? do
      VCR.use_cassette('request_mozilla_org_with_incorrect_ca_file') do
        request = RestMan::Request.new(
          :method => :get,
          :url => 'https://www.mozilla.org',
          :ssl_ca_file => File.join(File.dirname(__FILE__), "certs", "verisign.crt")
        )
        expect { request.execute }.to raise_error(OpenSSL::SSL::SSLError)
      end
    end

    # On OS X, this test fails since Apple has patched OpenSSL to always fall
    # back on the system CA store.
    it "is unsuccessful with an incorrect ca_path", :unless => RestMan::Platform.mac_mri? do
      VCR.use_cassette('request_mozilla_org_with_incorrect_ca_path') do
        request = RestMan::Request.new(
          :method => :get,
          :url => 'https://www.mozilla.org',
          :ssl_ca_path => File.join(File.dirname(__FILE__), "capath_verisign")
        )
        expect { request.execute }.to raise_error(OpenSSL::SSL::SSLError)
      end
    end

    it "is successful using the default system cert store" do
      VCR.use_cassette('request_mozilla_org_with_system_cert') do
        request = RestMan::Request.new(
          :method => :get,
          :url => 'https://www.mozilla.org',
          :verify_ssl => true,
        )
        expect {request.execute }.to_not raise_error
      end
    end


    # verify_callback is not works well with VCR
    # it "executes the verify_callback" do
    #   ran_callback = false
    #   request = RestMan::Request.new(
    #     :method => :get,
    #     :url => 'https://www.mozilla.org',
    #     :verify_ssl => true,
    #     :ssl_verify_callback => lambda { |preverify_ok, store_ctx|
    #       ran_callback = true
    #       preverify_ok
    #     },
    #   )
    #   expect {request.execute }.to_not raise_error
    #   expect(ran_callback).to eq(true)
    # end

    it "fails verification when the callback returns false",
       :unless => RestMan::Platform.mac_mri? do
      VCR.use_cassette('request_mozilla_org_callback_returns_false') do
        request = RestMan::Request.new(
          :method => :get,
          :url => 'https://www.mozilla.org',
          :verify_ssl => true,
          :ssl_verify_callback => lambda { |preverify_ok, store_ctx| false },
        )
        expect { request.execute }.to raise_error(OpenSSL::SSL::SSLError)
      end
    end

    it "succeeds verification when the callback returns true",
       :unless => RestMan::Platform.mac_mri? do
      VCR.use_cassette('request_mozilla_org_callback_returns_true') do
        request = RestMan::Request.new(
          :method => :get,
          :url => 'https://www.mozilla.org',
          :verify_ssl => true,
          :ssl_ca_file => File.join(File.dirname(__FILE__), "certs", "verisign.crt"),
          :ssl_verify_callback => lambda { |preverify_ok, store_ctx| true },
        )
        expect { request.execute }.to_not raise_error
      end
    end
  end

  describe "timeouts" do
    it "raises OpenTimeout when it hits an open timeout" do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Net::OpenTimeout.new)

      request = RestMan::Request.new(
        :method => :get,
        :url => 'http://www.mozilla.org',
        :open_timeout => 1e-10,
      )
      expect { request.execute }.to(
        raise_error(RestMan::Exceptions::OpenTimeout))
    end

    it "raises ReadTimeout when it hits a read timeout via :read_timeout" do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Net::ReadTimeout.new)

      request = RestMan::Request.new(
        :method => :get,
        :url => 'https://www.mozilla.org',
        :read_timeout => 1e-10,
      )
      expect { request.execute }.to(
        raise_error(RestMan::Exceptions::ReadTimeout))
    end

    it "raises WriteTimeout when it hits a write timeout via :write_timeout" do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Net::WriteTimeout.new)

      request = RestMan::Request.new(
        :method => :post,
        :url => 'https://www.mozilla.org',
        :write_timeout => 1e-10,
      )
      expect { request.execute }.to(
        raise_error(RestMan::Exceptions::WriteTimeout))
    end
  end

end
