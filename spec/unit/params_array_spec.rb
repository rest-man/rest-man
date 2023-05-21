require_relative '_lib'

describe RestMan::ParamsArray do

  describe '.new + .to_a' do
    it 'accepts various types of containers' do
      parse = lambda do |input, to:|
        expect(RestMan::ParamsArray.new(input).to_a).to eq to
      end

      parse.([[:foo, 123], [:foo, 456], [:bar, 789], [:empty, nil]], to: [[:foo, 123], [:foo, 456], [:bar, 789], [:empty, nil]])
      parse.([{foo: 123},  {foo: 456},  {bar: 789},  {empty: nil}],  to: [[:foo, 123], [:foo, 456], [:bar, 789], [:empty, nil]])
      parse.([{foo: 123},  {foo: 456},  {bar: 789},  {empty: nil}],  to: [[:foo, 123], [:foo, 456], [:bar, 789], [:empty, nil]])
      parse.([{foo: 123},  [:foo, 456], {bar: 789},  {empty: nil}],  to: [[:foo, 123], [:foo, 456], [:bar, 789], [:empty, nil]])
      parse.([{foo: 123},  [:foo, 456], {bar: 789},  [:empty]],      to: [[:foo, 123], [:foo, 456], [:bar, 789], [:empty, nil]])
      parse.([], to: [])

      expect(RestMan::ParamsArray.new([]).to_a).to eq []
      expect(RestMan::ParamsArray.new([]).empty?).to eq true
    end

    it 'rejects various invalid input' do
      expect {
        RestMan::ParamsArray.new([[]])
      }.to raise_error(IndexError)

      expect {
        RestMan::ParamsArray.new([[1,2,3]])
      }.to raise_error(ArgumentError)

      expect {
        RestMan::ParamsArray.new([1,2,3])
      }.to raise_error(NoMethodError)
    end
  end

  it '#emtpy?' do
    expect(RestMan::ParamsArray.new([]).empty?).to eq true
    expect(RestMan::ParamsArray.new({foo: 1}).empty?).to eq false
  end
end
