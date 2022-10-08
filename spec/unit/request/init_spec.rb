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

end
