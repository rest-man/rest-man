require_relative "../../../_lib"

RSpec.describe RestMan::Request::Init::Url::AddQueryFromHeaders do

  it 'should handle basic URL params' do
    expect(RestMan::Request::Init::Url::AddQueryFromHeaders.call('https://example.com/foo', params: {key1: 123, key2: 'abc'})).
      to eq 'https://example.com/foo?key1=123&key2=abc'

    expect(RestMan::Request::Init::Url::AddQueryFromHeaders.call('https://example.com/foo', params: {'key1' => 123})).
      to eq 'https://example.com/foo?key1=123'

    expect(RestMan::Request::Init::Url::AddQueryFromHeaders.call('https://example.com/path',
                                params: {foo: 'one two', bar: 'three + four == seven'})).
      to eq 'https://example.com/path?foo=one+two&bar=three+%2B+four+%3D%3D+seven'
  end

  it 'should combine with & when URL params already exist' do
    expect(RestMan::Request::Init::Url::AddQueryFromHeaders.call('https://example.com/path?foo=1', params: {bar: 2})).
      to eq 'https://example.com/path?foo=1&bar=2'
  end

  it 'should handle complex nested URL params per Rack / Rails conventions' do
    expect(RestMan::Request::Init::Url::AddQueryFromHeaders.call('https://example.com/', params: {
      foo: [1,2,3],
      null: nil,
      falsy: false,
      math: '2+2=4',
      nested: {'key + escaped' => 'value + escaped', other: [], arr: [1,2]},
    })).to eq 'https://example.com/?foo[]=1&foo[]=2&foo[]=3&null&falsy=false&math=2%2B2%3D4' \
                  '&nested[key+%2B+escaped]=value+%2B+escaped&nested[other]' \
                  '&nested[arr][]=1&nested[arr][]=2'
  end

  it 'should handle ParamsArray objects' do
    expect(RestMan::Request::Init::Url::AddQueryFromHeaders.call('https://example.com/',
      params: RestMan::ParamsArray.new([[:foo, 1], [:foo, 2]])
    )).to eq 'https://example.com/?foo=1&foo=2'
  end

end
