module RestMan
  class Request
    module Init

      autoload :Url, 'restman/request/init/url'

      include ActiveMethod

      module_function

      # :include: _doc/lib/restman/request/init/http_method.rdoc
      def http_method(args)
        method = args[:method]
        raise ArgumentError.new('must pass :method') unless method

        method.to_s.downcase
      end

      def headers(args)
        (args[:headers] || {}).dup
      end

      active_method :url, module_function: true

    end
  end
end