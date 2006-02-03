require File.dirname(__FILE__) + '/../test_helper'

class TrackbackTest < Test::Unit::TestCase
  fixtures :trackbacks

  def setup
    @trackback = Trackback.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Trackback,  @trackback
  end
end
