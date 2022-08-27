require 'http/accept'

module RestMan
  # Various utility methods
  module Utils

    # :include: _doc/lib/restman/utils/get_encoding_from_headers.rdoc
    def self.get_encoding_from_headers(headers)
      type_header = headers[:content_type]
      return nil unless type_header

      # TODO: remove this hack once we drop support for Ruby 2.0
      if RUBY_VERSION.start_with?('2.0')
        _content_type, params = deprecated_cgi_parse_header(type_header)

        if params.include?('charset')
          return params.fetch('charset').gsub(/(\A["']*)|(["']*\z)/, '')
        end

      else

        begin
          _content_type, params = cgi_parse_header(type_header)
        rescue HTTP::Accept::ParseError
          return nil
        else
          params['charset']
        end
      end
    end

    # :include: _doc/lib/restman/utils/cgi_parse_header.rdoc
    def self.cgi_parse_header(line)
      types = HTTP::Accept::MediaTypes.parse(line)

      if types.empty?
        raise HTTP::Accept::ParseError.new("Found no types in header line")
      end

      [types.first.mime_type, types.first.parameters]
    end

    # :include: _doc/lib/restman/utils/_cgi_parseparam.rdoc
    def self._cgi_parseparam(s)
      return enum_for(__method__, s) unless block_given?

      while s[0] == ';'
        s = s[1..-1]
        ends = s.index(';')
        while ends && ends > 0 \
              && (s[0...ends].count('"') -
                  s[0...ends].scan('\"').count) % 2 != 0
          ends = s.index(';', ends + 1)
        end
        if ends.nil?
          ends = s.length
        end
        f = s[0...ends]
        yield f.strip
        s = s[ends..-1]
      end
      nil
    end

    # :include: _doc/lib/restman/utils/deprecated_cgi_parse_header.rdoc
    def self.deprecated_cgi_parse_header(line)
      parts = _cgi_parseparam(';' + line)
      key = parts.next
      pdict = {}

      begin
        while (p = parts.next)
          i = p.index('=')
          if i
            name = p[0...i].strip.downcase
            value = p[i+1..-1].strip
            if value.length >= 2 && value[0] == '"' && value[-1] == '"'
              value = value[1...-1]
              value = value.gsub('\\\\', '\\').gsub('\\"', '"')
            end
            pdict[name] = value
          end
        end
      rescue StopIteration
      end

      [key, pdict]
    end

    # :include: _doc/lib/restman/utils/encode_query_string.rdoc
    def self.encode_query_string(object)
      flatten_params(object, true).map {|k, v| v.nil? ? k : "#{k}=#{v}" }.join('&')
    end

    # :include: _doc/lib/restman/utils/flatten_params.rdoc
    def self.flatten_params(object, uri_escape=false, parent_key=nil)
      unless object.is_a?(Hash) || object.is_a?(ParamsArray) ||
             (parent_key && object.is_a?(Array))
        raise ArgumentError.new('expected Hash or ParamsArray, got: ' + object.inspect)
      end

      # transform empty collections into nil, where possible
      if object.empty? && parent_key
        return [[parent_key, nil]]
      end

      # This is essentially .map(), but we need to do += for nested containers
      object.reduce([]) { |result, item|
        if object.is_a?(Array)
          # item is already the value
          k = nil
          v = item
        else
          # item is a key, value pair
          k, v = item
          k = escape(k.to_s) if uri_escape
        end

        processed_key = parent_key ? "#{parent_key}[#{k}]" : k

        case v
        when Array, Hash, ParamsArray
          result.concat flatten_params(v, uri_escape, processed_key)
        else
          v = escape(v.to_s) if uri_escape && v
          result << [processed_key, v]
        end
      }
    end

    # Encode string for safe transport by URI or form encoding. This uses a CGI
    # style escape, which transforms ` ` into `+` and various special
    # characters into percent encoded forms.
    #
    # This calls URI.encode_www_form_component for the implementation. The only
    # difference between this and CGI.escape is that it does not escape `*`.
    # http://stackoverflow.com/questions/25085992/
    #
    # @see URI.encode_www_form_component
    #
    def self.escape(string)
      URI.encode_www_form_component(string)
    end
  end
end
