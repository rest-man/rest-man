require_relative '_lib'

describe SimpleRestClient do
  describe "API" do
    it "GET" do
      expect(SimpleRestClient::Request).to receive(:execute).with(:method => :get, :url => 'http://some/resource', :headers => {})
      SimpleRestClient.get('http://some/resource')
    end

    it "POST" do
      expect(SimpleRestClient::Request).to receive(:execute).with(:method => :post, :url => 'http://some/resource', :payload => 'payload', :headers => {})
      SimpleRestClient.post('http://some/resource', 'payload')
    end

    it "PUT" do
      expect(SimpleRestClient::Request).to receive(:execute).with(:method => :put, :url => 'http://some/resource', :payload => 'payload', :headers => {})
      SimpleRestClient.put('http://some/resource', 'payload')
    end

    it "PATCH" do
      expect(SimpleRestClient::Request).to receive(:execute).with(:method => :patch, :url => 'http://some/resource', :payload => 'payload', :headers => {})
      SimpleRestClient.patch('http://some/resource', 'payload')
    end

    it "DELETE" do
      expect(SimpleRestClient::Request).to receive(:execute).with(:method => :delete, :url => 'http://some/resource', :headers => {})
      SimpleRestClient.delete('http://some/resource')
    end

    it "HEAD" do
      expect(SimpleRestClient::Request).to receive(:execute).with(:method => :head, :url => 'http://some/resource', :headers => {})
      SimpleRestClient.head('http://some/resource')
    end

    it "OPTIONS" do
      expect(SimpleRestClient::Request).to receive(:execute).with(:method => :options, :url => 'http://some/resource', :headers => {})
      SimpleRestClient.options('http://some/resource')
    end
  end

  describe "logging" do
    after do
      SimpleRestClient.log = nil
    end

    it "uses << if the log is not a string" do
      log = SimpleRestClient.log = []
      expect(log).to receive(:<<).with('xyz')
      SimpleRestClient.log << 'xyz'
    end

    it "displays the log to stdout" do
      SimpleRestClient.log = 'stdout'
      expect(STDOUT).to receive(:puts).with('xyz')
      SimpleRestClient.log << 'xyz'
    end

    it "displays the log to stderr" do
      SimpleRestClient.log = 'stderr'
      expect(STDERR).to receive(:puts).with('xyz')
      SimpleRestClient.log << 'xyz'
    end

    it "append the log to the requested filename" do
      SimpleRestClient.log = '/tmp/simplerestclient.log'
      f = double('file handle')
      expect(File).to receive(:open).with('/tmp/simplerestclient.log', 'a').and_yield(f)
      expect(f).to receive(:puts).with('xyz')
      SimpleRestClient.log << 'xyz'
    end
  end

  describe 'version' do
    # test that there is a sane version number to avoid accidental 0.0.0 again
    it 'has a version > 1.0.0.alpha, < 2.0' do
      ver = Gem::Version.new(SimpleRestClient.version)
      expect(Gem::Requirement.new('> 1.0.0.alpha', '< 2.0')).to be_satisfied_by(ver)
    end
  end
end
