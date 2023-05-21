require_relative '_lib'

describe RestMan::Utils do

  describe '.get_encoding_from_headers' do

    let(:get_encoding_from_headers) { RestMan::Utils.get_encoding_from_headers(headers) }

    context 'with valid content_type' do
      let(:headers) {{content_type: 'text/plain'}}

      it 'assumes no encoding by default' do
        expect(get_encoding_from_headers).to eq(nil)
      end
    end

    context 'with invalid content_type like "blah"' do
      let(:headers) {{content_type: 'blah'}}

      it 'return nil' do
        expect(get_encoding_from_headers).to eq(nil)
      end
    end

    context 'with invalid content_type like "foo; bar=baz"' do
      let(:headers) {{content_type: 'foo; bar=baz'}}

      it 'return nil' do
        expect(get_encoding_from_headers).to eq(nil)
      end
    end

    context 'with invalid content_type like empty headers' do
      let(:headers) {{}}

      it 'return nil' do
        expect(get_encoding_from_headers).to eq(nil)
      end
    end

    context 'with valid content_type with charset UTF-8' do
      let(:headers) {{content_type: 'text/plain; charset=UTF-8'}}

      it 'return UTF-8' do
        expect(get_encoding_from_headers).to eq('UTF-8')
      end
    end

    context 'with valid content_type with charset ISO-8859-1' do
      let(:headers) {{content_type: 'text/plain; charset=ISO-8859-1'}}

      it 'return ISO-8859-1' do
        expect(get_encoding_from_headers).to eq('ISO-8859-1')
      end
    end

    context 'with valid content_type with charset windows-1251' do
      let(:headers) {{content_type: 'text/plain; charset=windows-1251'}}

      it 'return windows-1251' do
        expect(get_encoding_from_headers).to eq('windows-1251')
      end
    end

    context 'with valid content_type with charset UTF-16' do
      let(:headers) {{content_type: 'text/plain; charset=UTF-16'}}

      it 'return UTF-16' do
        expect(get_encoding_from_headers).to eq('UTF-16')
      end
    end

  end

  describe '.cgi_parse_header' do

    let(:parse) { ->(line, to:) {
      expect(RestMan::Utils.cgi_parse_header(line)).to eq(to)
    }}

    it { parse.('text/plain',                                   to: ['text/plain', {}]) }
    it { parse.('text/vnd.just.made.this.up',                   to: ['text/vnd.just.made.this.up', {}]) }
    it { parse.('text/plain;charset=us-ascii',                  to: ['text/plain', {'charset' => 'us-ascii'}]) }
    it { parse.('text/plain ; charset="us-ascii"',              to: ['text/plain', {'charset' => 'us-ascii'}]) }
    it { parse.('text/plain ; charset="us-ascii"; another=opt', to: ['text/plain', {'charset' => 'us-ascii', 'another' => 'opt'}]) }
    it { parse.('foo/bar; filename="silly.txt"',                to: ['foo/bar', {'filename' => 'silly.txt'}]) }
    it { parse.('foo/bar; filename="strange;name"',             to: ['foo/bar', {'filename' => 'strange;name'}]) }
    it { parse.('foo/bar; filename="strange;name";size=123',    to: ['foo/bar', {'filename' => 'strange;name', 'size' => '123'}]) }
    it { parse.('foo/bar; name="files"; filename="fo\\"o;bar"', to: ['foo/bar', {'name' => 'files', 'filename' => 'fo"o;bar'}]) }

  end

  describe '.encode_query_string' do
    let(:encoding) { -> (input, to:) {
      expect(RestMan::Utils.encode_query_string(input)).to eq to
    } }

    it 'handles simple hashes' do
      encoding.({foo: 123, bar: 456},         to: 'foo=123&bar=456')
      encoding.({'foo' => 123, 'bar' => 456}, to: 'foo=123&bar=456')
      encoding.({foo: 'abc', bar: 'one two'}, to: 'foo=abc&bar=one+two')
      encoding.({escaped: '1+2=3'},           to: 'escaped=1%2B2%3D3')
      encoding.({'escaped + key' => 'foo'},   to: 'escaped+%2B+key=foo')
    end

    it 'handles simple arrays' do
      encoding.({foo: [1, 2, 3]},                 to: 'foo[]=1&foo[]=2&foo[]=3')
      encoding.({foo: %w{a b c}, bar: [1, 2, 3]}, to: 'foo[]=a&foo[]=b&foo[]=c&bar[]=1&bar[]=2&bar[]=3')
      encoding.({foo: ['one two', 3]},            to: 'foo[]=one+two&foo[]=3')
      encoding.({'a+b' => [1,2,3]},               to: 'a%2Bb[]=1&a%2Bb[]=2&a%2Bb[]=3')
    end

    it 'handles nested hashes' do
      encoding.({outer: {foo: 123, bar: 456}},         to: 'outer[foo]=123&outer[bar]=456')
      encoding.({outer: {foo: [1, 2, 3], bar: 'baz'}}, to: 'outer[foo][]=1&outer[foo][]=2&outer[foo][]=3&outer[bar]=baz')
    end

    it 'handles null and empty values' do
      encoding.({string: '', empty: nil, list: [], hash: {}, falsey: false }, to: 'string=&empty&list&hash&falsey=false')
    end

    it 'handles nested nulls' do
      encoding.({foo: {string: '', empty: nil}}, to: 'foo[string]=&foo[empty]')
    end

    it 'handles deep nesting' do
      encoding.({coords: [{x: 1, y: 0}, {x: 2}, {x: 3}]}, to: 'coords[][x]=1&coords[][y]=0&coords[][x]=2&coords[][x]=3')
    end

    it 'handles multiple fields with the same name using ParamsArray' do
      encoding.(RestMan::ParamsArray.new([[:foo, 1], [:foo, 2], [:foo, 3]]), to: 'foo=1&foo=2&foo=3')
    end

    it 'handles nested ParamsArrays' do
      encoding.({foo: RestMan::ParamsArray.new([[:a, 1], [:a, 2]])},        to: 'foo[a]=1&foo[a]=2')
      encoding.(RestMan::ParamsArray.new([[:foo, {a: 1}], [:foo, {a: 2}]]), to: 'foo[a]=1&foo[a]=2')
    end
  end
end
