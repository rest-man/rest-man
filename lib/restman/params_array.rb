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
      array.map {|v| ProcessPair.call(v) }
    end

  end
end
