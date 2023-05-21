require_relative '../_lib'

RSpec.describe "RestMan::Request::Init" do

  describe ".http_method" do
    context 'when :method is nil' do
      let(:args) { {} }

      it "raise ArgumentError" do
        expect {
          RestMan::Request::Init.http_method(args)
        }.to raise_error(ArgumentError, "must pass :method")
      end
    end

    context 'when :method is not nil' do
      let(:args) { {method: :POST} }

      it "return post" do
        expect(RestMan::Request::Init.http_method(args)).to eq('post')
      end
    end
  end

  describe ".headers" do
    let(:args) { {} }

    context "when :headers is nil" do
      it "return {}" do
        expect(RestMan::Request::Init.headers(args)).to eq({})
      end
    end

    context "when :headers is not nil" do
      let(:args) { { headers: { foo: 'bar' } } }

      it "return args[:headers].dup" do
        expect(RestMan::Request::Init.headers(args)).to eq({foo: 'bar'})
        expect(RestMan::Request::Init.headers(args).object_id).not_to eq(args[:headers])
      end
    end
  end

  describe ".uri" do
    it 'should parse to an URI' do
      uri = RestMan::Request::Init.uri('http://example.com')
      expect(uri).to be_a(URI)
    end

    it 'should reject valid URIs with no hostname' do
      expect {
        RestMan::Request::Init.uri('http:///')
      }.to raise_error(URI::InvalidURIError, "bad URI(no host provided): http:///")
    end

    it 'should reject invalid URIs' do
      expect {
        RestMan::Request::Init.uri('http://::')
      }.to raise_error(URI::InvalidURIError)
    end
  end

  describe ".auth" do
    it "doesn't overwrite user and password (which may have already been set by the Resource constructor) if there is no user/password in the url" do
      user, password = RestMan::Request::Init.auth(URI.parse('http://example.com/resource'), {user: 'beth', password: 'pass2'})
      expect(user).to eq 'beth'
      expect(password).to eq 'pass2'
    end

    it 'uses the username and password from the URL' do
      user, password = RestMan::Request::Init.auth(URI.parse('http://person:secret@example.com/resource'), {})
      expect(user).to eq 'person'
      expect(password).to eq 'secret'
    end

    it 'overrides URL user/pass with explicit options' do
      user, password = RestMan::Request::Init.auth(URI.parse('http://person:secret@example.com/resource'), {user: 'beth', password: 'pass2'})
      expect(user).to eq 'beth'
      expect(password).to eq 'pass2'
    end
  end

end
