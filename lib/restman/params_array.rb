module RestMan

  # :include: _doc/lib/restman/params_array.rdoc
  class ParamsArray
    include Enumerable

    # :include: _doc/lib/restman/params_array/new.rdoc
    def initialize(array)
      @array = process_input(array)
    end

    def each(*args, &blk)
      @array.each(*args, &blk)
    end

    def empty?
      @array.empty?
    end

    private

    def process_input(array)
      array.map {|v| process_pair(v) }
    end

    # :include: _doc/lib/restman/params_array/process_pair.rdoc
    def process_pair(pair)
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
        process_pair(pair.to_a)
      end
    end
  end
end
