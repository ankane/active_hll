require_relative "test_helper"

class CountTest < Minitest::Test
  def test_count
    EventRollup.create!.hll_add(visitor_ids: [1, 2, 3])
    EventRollup.create!.hll_add(visitor_ids: [3, 4, 5])
    assert_equal 5, EventRollup.hll_count(:visitor_ids)
  end

  def test_order
    EventRollup.create!(time_bucket: Date.yesterday).hll_add(visitor_ids: [1, 2, 3])
    EventRollup.create!(time_bucket: Date.current).hll_add(visitor_ids: [3, 4, 5])
    assert_equal 5, EventRollup.order(:time_bucket).hll_count(:visitor_ids)
  end

  def test_group
    EventRollup.create!(time_bucket: Date.yesterday).hll_add(visitor_ids: [1, 2, 3])
    EventRollup.create!(time_bucket: Date.current).hll_add(visitor_ids: [3, 4, 5])
    expected = {Date.yesterday => 3, Date.current => 3}
    assert_equal expected, EventRollup.group(:time_bucket).hll_count(:visitor_ids)
  end

  def test_groupdate
    week = Date.current.beginning_of_week(:sunday)
    EventRollup.create!(time_bucket: week).hll_add(visitor_ids: [1, 2, 3])
    EventRollup.create!(time_bucket: week + 1).hll_add(visitor_ids: [3, 4, 5])
    expected = {week => 5}
    assert_equal expected, EventRollup.group_by_week(:time_bucket, time_zone: false).hll_count(:visitor_ids)
  end

  def test_groupdate_zeros
    assert_equal [0], EventRollup.group_by_week(:time_bucket, last: 1).hll_count(:visitor_ids).values
  end

  def test_expression_no_arel
    error = assert_raises(ActiveRecord::UnknownAttributeReference) do
      EventRollup.hll_count("counter + 1")
    end
    assert_equal "Query method called with non-attribute argument(s): \"counter + 1\". Use Arel.sql() for known-safe values.", error.message
  end
end
