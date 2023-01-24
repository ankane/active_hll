module ActiveHll
  module Utils
    class << self
      def hll_hash_sql(klass, value)
        hash_function =
          case value
          when true, false
            "hll_hash_boolean"
          when Integer
            "hll_hash_bigint"
          when String
            "hll_hash_text"
          else
            raise ArgumentError, "Unexpected type: #{value.class.name}"
          end
        quoted_value = klass.connection.quote(value)
        "#{hash_function}(#{quoted_value})"
      end

      def hll_calculate(relation, operation, column, default_value:)
        sql, relation, group_values = hll_calculate_sql(relation, operation, column)
        result = relation.connection.select_all(sql)

        # typecast
        rows = []
        columns = result.columns
        result.rows.each do |untyped_row|
          rows << (result.column_types.empty? ? untyped_row : columns.each_with_index.map { |c, i| untyped_row[i] && result.column_types[c] ? result.column_types[c].deserialize(untyped_row[i]) : untyped_row[i] })
        end

        result =
          if group_values.any?
            Hash[rows.map { |r| [r.size == 2 ? r[0] : r[0..-2], r[-1]] }]
          else
            rows[0] && rows[0][0]
          end

        result = Groupdate.process_result(relation, result, default_value: default_value) if defined?(Groupdate.process_result)

        result
      end

      def hll_calculate_sql(relation, operation, column)
        # basic version of Active Record disallow_raw_sql!
        # symbol = column (safe), Arel node = SQL (safe), other = untrusted
        # matches table.column and column
        unless column.is_a?(Symbol) || column.is_a?(Arel::Nodes::SqlLiteral)
          column = column.to_s
          unless /\A\w+(\.\w+)?\z/i.match(column)
            raise ActiveRecord::UnknownAttributeReference, "Query method called with non-attribute argument(s): #{column.inspect}. Use Arel.sql() for known-safe values."
          end
        end

        # column resolution
        node = relation.all.send(:arel_columns, [column]).first
        node = Arel::Nodes::SqlLiteral.new(node) if node.is_a?(String)
        column = relation.connection.visitor.accept(node, Arel::Collectors::SQLString.new).value

        group_values = relation.all.group_values

        relation = relation.unscope(:select).select(*group_values, operation % [column])

        # same as average
        relation = relation.unscope(:order).distinct!(false) if group_values.empty?

        [relation.to_sql, relation, group_values]
      end
    end
  end
end
