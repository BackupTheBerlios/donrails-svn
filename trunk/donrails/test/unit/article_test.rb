require File.dirname(__FILE__) + '/../test_helper'

class ArticleTest < Test::Unit::TestCase
  fixtures :articles, :categories, :comments, :comments_articles, :categories_articles

  def setup
#    @article = Article.find(1)
    @article = Article.new
#    p @article
#    p 'moge'
#    @urllist = ['http://localhost:3000/notes/catch_ping/']
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Article,  @article
#    p @article
  end

end
