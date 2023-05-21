require 'spec_helper'

describe RestMan::ParamsArray::ProcessPair do

  let(:process_pair) { RestMan::ParamsArray::ProcessPair.call(pair) }

  context 'when pair is a hash' do
    context 'which containts only one key-value pair' do
      let(:pair) { {a: 1} }

      it "return the array [key, value]" do
        expect(process_pair).to eq([:a, 1])
      end
    end

    context 'which containts multiple key-value pairs' do
      let(:pair) { { a: 1, b: 2 } }

      it "raise ArgumentError" do
        expect{process_pair}.to raise_error(ArgumentError, "Bad # of fields for pair: {:a=>1, :b=>2}")
      end
    end
  end

  context 'when pair is an array' do
    context 'which containts only one item like [key]' do
      let(:pair) { [:a] }

      it "return the array [key, nil]" do
        expect(process_pair).to eq([:a, nil])
      end
    end

    context 'which containts two items like [key, value]' do
      let(:pair) { [:a, 1] }

      it "return the array [key, value]" do
        expect(process_pair).to eq([:a, 1])
      end
    end

    context 'which containts more than two items like [a, b, c]' do
      let(:pair) { [:a, 1, :b] }

      it "raise ArgumentError" do
        expect{process_pair}.to raise_error(ArgumentError, "Bad # of fields for pair: [:a, 1, :b]")
      end
    end
  end

  context 'when pair is an array like object' do
    let(:pair) { double('ArrayLikeObject', to_a: [:a, 1]) }

    it 'convert it to array' do
      expect(process_pair).to eq([:a, 1])
    end
  end

end
