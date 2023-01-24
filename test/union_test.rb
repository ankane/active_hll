require_relative "test_helper"

class UnionTest < Minitest::Test
  def test_union
    EventRollup.create!.hll_add(visitor_ids: [1, 2, 3])
    EventRollup.create!.hll_add(visitor_ids: [3, 4, 5])
    event = EventRollup.create!(visitor_ids: EventRollup.hll_union(:visitor_ids))
    assert_equal 5, event.hll_count(:visitor_ids)
  end

  def test_expression_no_arel
    error = assert_raises(ActiveRecord::UnknownAttributeReference) do
      EventRollup.hll_union("counter + 1")
    end
    assert_equal "Query method called with non-attribute argument(s): \"counter + 1\". Use Arel.sql() for known-safe values.", error.message
  end
end
