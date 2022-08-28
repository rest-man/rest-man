module RestMan
  class ParamsArray

    # :include: _doc/lib/restman/params_array/process_pair.rdoc
    class ProcessPair < ActiveMethod::Base

      argument :pair

      def call
        case pair
        when Hash
          if pair.length != 1
            raise ArgumentError.new("Bad # of fields for pair: #{pair.inspect}")
          end
          pair.to_a.fetch(0)
        when Array
          if pair.length > 2
            raise ArgumentError.new("Bad # of fields for pair: #{pair.inspect}")
          end
          [pair.fetch(0), pair[1]]
        else
          # recurse, converting any non-array to an array
          ProcessPair.call(pair.to_a)
        end
      end

    end
  end
end
