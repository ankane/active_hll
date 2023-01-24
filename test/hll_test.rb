require_relative "test_helper"

class HllTest < Minitest::Test
  def test_inspect
    EventRollup.create!.hll_add(visitor_ids: [1, 2, 3])
    rollup = EventRollup.last
    assert_kind_of ActiveHll::Hll, rollup.visitor_ids
    assert_equal "(hll)", rollup.visitor_ids.inspect
    assert_match "visitor_ids: (hll)", rollup.inspect
  end

  def test_methods
    item = EventRollup.create!
    item.hll_add(visitor_ids: ["a", "b", "c"])
    hll = item.reload.visitor_ids
    assert_equal 1, hll.schema_version
    assert_equal 2, hll.type
    assert_equal 11, hll.log2m
    assert_equal 5, hll.regwidth
    assert_equal (-1), hll.expthresh
    assert_equal 1, hll.sparseon
    assert_equal [-8839064797231613815, -8198557465434950441, 8833996863197925870], hll.data
  end
end
