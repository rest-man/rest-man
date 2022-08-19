require_relative '_lib'

describe RestMan do
  describe "API" do
    it "GET" do
      expect(RestMan::Request).to receive(:execute).with(:method => :get, :url => 'http://some/resource', :headers => {})
      RestMan.get('http://some/resource')
    end

    it "POST" do
      expect(RestMan::Request).to receive(:execute).with(:method => :post, :url => 'http://some/resource', :payload => 'payload', :headers => {})
      RestMan.post('http://some/resource', 'payload')
    end

    it "PUT" do
      expect(RestMan::Request).to receive(:execute).with(:method => :put, :url => 'http://some/resource', :payload => 'payload', :headers => {})
      RestMan.put('http://some/resource', 'payload')
    end

    it "PATCH" do
      expect(RestMan::Request).to receive(:execute).with(:method => :patch, :url => 'http://some/resource', :payload => 'payload', :headers => {})
      RestMan.patch('http://some/resource', 'payload')
    end

    it "DELETE" do
      expect(RestMan::Request).to receive(:execute).with(:method => :delete, :url => 'http://some/resource', :headers => {})
      RestMan.delete('http://some/resource')
    end

    it "HEAD" do
      expect(RestMan::Request).to receive(:execute).with(:method => :head, :url => 'http://some/resource', :headers => {})
      RestMan.head('http://some/resource')
    end

    it "OPTIONS" do
      expect(RestMan::Request).to receive(:execute).with(:method => :options, :url => 'http://some/resource', :headers => {})
      RestMan.options('http://some/resource')
    end
  end

  describe "logging" do
    after do
      RestMan.log = nil
    end

    it "uses << if the log is not a string" do
      log = RestMan.log = []
      expect(log).to receive(:<<).with('xyz')
      RestMan.log << 'xyz'
    end

    it "displays the log to stdout" do
      RestMan.log = 'stdout'
      expect(STDOUT).to receive(:puts).with('xyz')
      RestMan.log << 'xyz'
    end

    it "displays the log to stderr" do
      RestMan.log = 'stderr'
      expect(STDERR).to receive(:puts).with('xyz')
      RestMan.log << 'xyz'
    end

    it "append the log to the requested filename" do
      RestMan.log = '/tmp/restman.log'
      f = double('file handle')
      expect(File).to receive(:open).with('/tmp/restman.log', 'a').and_yield(f)
      expect(f).to receive(:puts).with('xyz')
      RestMan.log << 'xyz'
    end
  end

  describe 'version' do
    # test that there is a sane version number to avoid accidental 0.0.0 again
    it 'has a version > 1.0.0.alpha, < 2.0' do
      ver = Gem::Version.new(RestMan.version)
      expect(Gem::Requirement.new('> 1.0.0.alpha', '< 2.0')).to be_satisfied_by(ver)
    end
  end
end
