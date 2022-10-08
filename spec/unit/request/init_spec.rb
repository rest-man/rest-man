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

end
