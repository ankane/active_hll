require_relative "test_helper"

class AggTest < Minitest::Test
  def test_agg
    create_events

    hlls = Event.group_by_day(:created_at).hll_agg(:visitor_id)

    3.times do
      EventRollup.upsert_all(
        hlls.map { |k, v| {time_bucket: k, visitor_ids: v} },
        unique_by: [:time_bucket]
      )
    end

    assert_equal 5, EventRollup.hll_count(:visitor_ids)
  end

  def test_expression_no_arel
    error = assert_raises(ActiveRecord::UnknownAttributeReference) do
      EventRollup.hll_agg("counter + 1")
    end
    assert_equal "Query method called with non-attribute argument(s): \"counter + 1\". Use Arel.sql() for known-safe values.", error.message
  end

  private

  def create_events
    now = Time.now
    [1, 1, 2, 3].each do |visitor_id|
      Event.create!(visitor_id: visitor_id, created_at: now - 2.days)
    end
    [3, 4, 5].each do |visitor_id|
      Event.create!(visitor_id: visitor_id, created_at: now)
    end
  end
end
