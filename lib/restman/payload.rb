require 'mime/types/columnar'

module RestMan
  module Payload
    extend self

    def generate(params)
      if params.is_a?(RestMan::Payload::Base)
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
        if has_file?(params)
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

    def has_file?(obj)
      case obj
      when Hash, ParamsArray
        obj.any? {|_, v| has_file?(v) }

      when Array
        obj.any? {|v| has_file?(v) }

      else
        obj.respond_to?(:path) && obj.respond_to?(:read)
      end
    end

  end
end
