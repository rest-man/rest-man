require 'mime/types/columnar'

module RestMan
  module Payload
    extend self

    def generate(params)
      if params.is_a?(RestMan::Payload::Base)
        # pass through Payload objects unchanged
        params
      elsif params.is_a?(String)
        Base.new(params)
      elsif params.is_a?(Hash)
        if params.delete(:multipart) == true || has_file?(params)
          Multipart.new(params)
        else
          UrlEncoded.new(params)
        end
      elsif params.is_a?(ParamsArray)
        if _has_file?(params)
          Multipart.new(params)
        else
          UrlEncoded.new(params)
        end
      elsif params.respond_to?(:read)
        Streamed.new(params)
      else
        nil
      end
    end

    def has_file?(params)
      unless params.is_a?(Hash)
        raise ArgumentError.new("Must pass Hash, not #{params.inspect}")
      end
      _has_file?(params)
    end

    def _has_file?(obj)
      case obj
      when Hash, ParamsArray
        obj.any? {|_, v| _has_file?(v) }
      when Array
        obj.any? {|v| _has_file?(v) }
      else
        obj.respond_to?(:path) && obj.respond_to?(:read)
      end
    end

  end
end
