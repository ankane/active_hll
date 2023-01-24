require_relative "test_helper"

class CreateTest < Minitest::Test
  def test_generate
    event = EventRollup.create!(visitor_ids: EventRollup.hll_generate([1, 2, 3]))
    assert_equal 3, event.hll_count(:visitor_ids)
  end

  def test_string
    error = assert_raises(ArgumentError) do
      EventRollup.create!(visitor_ids: "hello")
    end
    assert_equal "can't cast String to hll", error.message
  end
end
