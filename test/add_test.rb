require_relative "test_helper"

class AddTest < Minitest::Test
  def test_string
    item = EventRollup.create!
    assert_nil item.hll_add(visitor_ids: "hello")
    assert_nil item.hll_add(visitor_ids: ["world", "!!!"])
    assert_equal 3, item.hll_count(:visitor_ids)
  end

  def test_boolean
    item = EventRollup.create!
    assert_nil item.hll_add(visitor_ids: true)
    assert_nil item.hll_add(visitor_ids: [true, false])
    assert_equal 2, item.hll_count(:visitor_ids)
  end

  def test_integer
    item = EventRollup.create!
    assert_nil item.hll_add(visitor_ids: 1)
    assert_nil item.hll_add(visitor_ids: [2, 3])
    assert_equal 3, item.hll_count(:visitor_ids)
  end

  def test_multiple_types
    item = EventRollup.create!
    assert_nil item.hll_add(visitor_ids: ["a", "b", "c", 1, 2, 3, true, false])
    assert_equal 8, item.hll_count(:visitor_ids)
  end

  def test_multiple_columns
    skip "TODO fix"

    item = OrderRollup.create!
    assert_nil item.hll_add(visitor_ids: 1, user_ids: 2)
    assert_equal 1, item.hll_count(:visitor_ids)
    assert_equal 1, item.hll_count(:user_ids)
  end

  def test_nil
    item = EventRollup.create!
    assert_equal 0, item.hll_count(:visitor_ids)
    assert_nil item.hll_add(visitor_ids: 1)
    assert_equal 1, item.hll_count(:visitor_ids)
  end

  def test_empty
    item = EventRollup.create!
    assert_nil item.hll_add(visitor_ids: [])
    assert_equal 0, item.hll_count(:visitor_ids)
  end

  def test_relation
    items = 3.times.map { |i| EventRollup.create!(id: i + 1) }
    assert_equal 2, EventRollup.where("id <= ?", 2).hll_add(visitor_ids: "hello")
    assert_equal [1, 1, 0], items.map { |item| item.hll_count(:visitor_ids) }
  end
end
