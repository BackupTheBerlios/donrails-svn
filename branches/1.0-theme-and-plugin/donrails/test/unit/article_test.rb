require File.dirname(__FILE__) + '/../test_helper'

class ArticleTest < Test::Unit::TestCase
  fixtures :articles

  def setup
    @article = Article.find(1)
    @urllist = ['http://localhost:3000/notes/catch_ping/']
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Article,  @article
  end

end
