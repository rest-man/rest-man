module RestMan
  class ParamsArray

    # :include: _doc/lib/restman/params_array/process_pair.rdoc
    class ProcessPair < ActiveMethod::Base

      argument :pair

      def call
        case pair
        when Hash
          convert_hash_pair_to_array
        when Array
          parse_array_pair
        else
          ProcessPair.call(pair.to_a)
        end
      end

      private

      def convert_hash_pair_to_array
        if pair.length != 1
          raise ArgumentError.new("Bad # of fields for pair: #{pair.inspect}")
        end

        pair.to_a.fetch(0)
      end

      def parse_array_pair
        if pair.length > 2
          raise ArgumentError.new("Bad # of fields for pair: #{pair.inspect}")
        end
        [pair.fetch(0), pair[1]]
      end

    end
  end
end
