# format of value
# https://github.com/aggregateknowledge/hll-storage-spec/blob/v1.0.0/STORAGE.md
module ActiveHll
  class Hll
    attr_reader :value

    def initialize(value)
      unless value.is_a?(String) && value.encoding == Encoding::BINARY
        raise ArgumentError, "Expected binary string"
      end

      @value = value
    end

    def inspect
      "(hll)"
    end

    def schema_version
      value[0].unpack1("C") >> 4
    end

    def type
      value[0].unpack1("C") & 0b00001111
    end

    def regwidth
      (value[1].unpack1("C") >> 5) + 1
    end

    def log2m
      value[1].unpack1("C") & 0b00011111
    end

    def sparseon
      (value[2].unpack1("C") & 0b01000000) >> 6
    end

    def expthresh
      t = value[2].unpack1("C") & 0b00111111
      t == 63 ? -1 : 2**(t - 1)
    end

    def data
      case type
      when 2
        value[3..-1].unpack("q>*")
      end
    end
  end
end
