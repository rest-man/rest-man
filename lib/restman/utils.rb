require 'http/accept'

module RestMan
  # Various utility methods
  module Utils

    # :include: _doc/lib/restman/utils/get_encoding_from_headers.rdoc
    def self.get_encoding_from_headers(headers)
      type_header = headers[:content_type]
      return nil unless type_header

      begin
        _content_type, params = cgi_parse_header(type_header)
      rescue HTTP::Accept::ParseError
        return nil
      else
        params['charset']
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

    # :include: _doc/lib/restman/utils/escape.rdoc
    def self.escape(string)
      URI.encode_www_form_component(string)
    end
  end
end
