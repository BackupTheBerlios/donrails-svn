require File.dirname(__FILE__) + '/../test_helper'

class AuthorsTest < Test::Unit::TestCase
  fixtures :authors

  def setup
    @authors = Authors.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Authors,  @authors
  end
end
