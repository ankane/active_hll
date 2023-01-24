module ActiveHll
  class Type < ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Bytea
    def type
      :hll
    end

    def serialize(value)
      if value.is_a?(Hll)
        value = value.value
      elsif !value.nil?
        raise ArgumentError, "can't cast #{value.class.name} to hll"
      end
      super(value)
    end

    def deserialize(value)
      value = super
      value.nil? ? value : Hll.new(value)
    end
  end
end
