require_relative "test_helper"

class MiscTest < Minitest::Test
  def test_schema
    file = Tempfile.new
    connection = ActiveRecord::VERSION::STRING.to_f >= 7.2 ? ActiveRecord::Base.connection_pool : ActiveRecord::Base.connection
    ActiveRecord::SchemaDumper.dump(connection, file)
    file.rewind
    schema = file.read
    refute_match "Could not dump table", schema
    load(file.path)
  end

  def test_select
    item = EventRollup.create!
    item.hll_add(visitor_ids: ["a", "b", "c"])
    assert_equal 3, EventRollup.select("id, hll_cardinality(visitor_ids) AS visitors_count").first.visitors_count
  end

  # no need for model method
  def test_print
    item = EventRollup.create!
    item.hll_add(visitor_ids: ["a", "b", "c"])
    output = EventRollup.where(id: item.id).pluck("hll_print(visitor_ids)::text").first
    assert_match "3 elements", output
  end

  def test_accuracy
    item = EventRollup.create!
    item.hll_add(visitor_ids: 1000.times.map { |i| "visitor#{i}" })
    assert_in_delta 1000, item.hll_count(:visitor_ids), 8
  end

  def test_likely_member
    today = Date.current

    item = EventRollup.create!(time_bucket: today - 1)
    item.hll_add(visitor_ids: ["a", "b", "c"])

    item = EventRollup.create!(time_bucket: today)
    item.hll_add(visitor_ids: ["c", "d", "e"])

    sql = <<~SQL
      SELECT
          time_bucket,
          visitor_ids = visitor_ids || hll_hash_text('a') AS likely_member
      FROM
          event_rollups;
    SQL
    result = EventRollup.connection.select_all(sql).to_a
    likely_members = result.to_h { |r| [Date.parse(r["time_bucket"]), r["likely_member"]] }
    assert_equal true, likely_members[today - 1]
    assert_equal false, likely_members[today]
  end
end
