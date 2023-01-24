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
