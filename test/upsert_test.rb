require_relative "test_helper"

class UpsertTest < Minitest::Test
  def test_upsert
    today = Date.current
    3.times do
      result = EventRollup.hll_upsert({time_bucket: today, visitor_ids: ["hello", "world"]})
      assert_kind_of ActiveRecord::Result, result
    end
    EventRollup.hll_upsert({time_bucket: today, visitor_ids: ["!!!"]})

    assert_equal 1, EventRollup.count
    rollup = EventRollup.last
    assert_equal today, rollup.time_bucket
    assert_equal 3, rollup.hll_count(:visitor_ids)
  end

  def test_empty
    today = Date.current
    3.times do
      result = EventRollup.hll_upsert({time_bucket: today, visitor_ids: []})
      assert_kind_of ActiveRecord::Result, result
    end

    assert_equal 1, EventRollup.count
    rollup = EventRollup.last
    assert_equal today, rollup.time_bucket
    assert_equal 0, rollup.hll_count(:visitor_ids)
  end

  def test_upsert_no_hll
    error = assert_raises(ArgumentError) do
      EventRollup.hll_upsert({time_bucket: Date.current})
    end
    assert_equal "No hll columns", error.message
  end

  def test_missing_column
    assert_raises(ActiveRecord::StatementInvalid) do
      EventRollup.hll_upsert({missing: Date.current, visitor_ids: ["hello", "world"]})
    end
  end

  def test_relation
    skip "todo: fix"

    assert_raises(NoMethodError) do
      EventRollup.all.hll_upsert({})
    end
  end
end
