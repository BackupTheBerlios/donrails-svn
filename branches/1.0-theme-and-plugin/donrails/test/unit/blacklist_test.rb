require File.dirname(__FILE__) + '/../test_helper'

class BlacklistTest < Test::Unit::TestCase
  fixtures :blacklists

  def setup
    @blacklist = Blacklist.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Blacklist,  @blacklist
  end
end
