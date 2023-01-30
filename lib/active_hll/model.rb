require "active_support/concern"

module ActiveHll
  module Model
    extend ActiveSupport::Concern

    class_methods do
      def hll_agg(column)
        Utils.hll_calculate(self, "hll_add_agg(hll_hash_any(%s)) AS hll_agg", column, default_value: nil)
      end

      def hll_union(column)
        Utils.hll_calculate(self, "hll_union_agg(%s) AS hll_union", column, default_value: nil)
      end

      def hll_count(column)
        Utils.hll_calculate(self, "hll_cardinality(hll_union_agg(%s)) AS hll_count", column, default_value: 0.0)
      end

      # experimental
      # doesn't work with non-default parameters
      def hll_generate(values)
        parts = ["hll_empty()"]

        values.each do |value|
          parts << Utils.hll_hash_sql(self, value)
        end

        result = connection.select_all("SELECT #{parts.join(" || ")}").rows[0][0]
        ActiveHll::Type.new.deserialize(result)
      end

      def hll_add(attributes)
        set_clauses =
          attributes.map do |attribute, values|
            values = [values] unless values.is_a?(Array)
            return 0 if values.empty?

            quoted_column = connection.quote_column_name(attribute)
            # possibly fetch parameters for the column in the future
            # for now, users should set a default value on the column
            parts = ["COALESCE(#{quoted_column}, hll_empty())"]

            values.each do |value|
              parts << Utils.hll_hash_sql(self, value)
            end

            "#{quoted_column} = #{parts.join(" || ")}"
          end

        update_all(set_clauses.join(", "))
      end

      # experimental
      def hll_upsert(attributes)
        hll_columns, other_columns = attributes.keys.partition { |a| columns_hash[a.to_s]&.type == :hll }

        # important! raise if column detection fails
        if hll_columns.empty?
          raise ArgumentError, "No hll columns"
        end

        quoted_table = connection.quote_table_name(table_name)

        quoted_hll_columns = hll_columns.map { |k| connection.quote_column_name(k) }
        quoted_other_columns = other_columns.map { |k| connection.quote_column_name(k) }
        quoted_columns = quoted_other_columns + quoted_hll_columns

        hll_values =
          hll_columns.map do |k|
            vs = attributes[k]
            vs = [vs] unless vs.is_a?(Array)
            vs.map { |v| Utils.hll_hash_sql(self, v) }.join(" || ")
          end
        other_values = other_columns.map { |k| connection.quote(attributes[k]) }

        insert_values = other_values + hll_values.map { |v| "hll_empty()#{v.size > 0 ? " || #{v}" : ""}" }
        update_values = quoted_hll_columns.zip(hll_values).map { |k, v| "#{k} = COALESCE(#{quoted_table}.#{k}, hll_empty())#{v.size > 0 ? " || #{v}" : ""}" }

        sql = "INSERT INTO #{quoted_table} (#{quoted_columns.join(", ")}) VALUES (#{insert_values.join(", ")}) ON CONFLICT (#{quoted_other_columns.join(", ")}) DO UPDATE SET #{update_values.join(", ")}"
        connection.exec_insert(sql, "#{name} Upsert")
      end
    end

    # doesn't update in-memory record attribute for performance
    def hll_add(attributes)
      self.class.where(id: id).hll_add(attributes)
      nil
    end

    def hll_count(attribute)
      quoted_column = self.class.connection.quote_column_name(attribute)
      self.class.where(id: id).pluck("hll_cardinality(#{quoted_column})").first || 0.0
    end
  end
end
