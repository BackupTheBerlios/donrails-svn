require 'test/unit'
require 'atomcheck'

class TC_AtomPost < Test::Unit::TestCase
  def setup
    @obj = AtomPost.new
    fc = open("#{ENV['HOME']}/.donrails/atompost-test.yaml", "r")
    conf = YAML::load(fc)
    @user = conf['user']
    @uri = conf['target_url']
    @pass = conf['pass']

    @tt = 'test title'
    @tb = 'test body'
    article = Article.find(:first, :conditions => ['title = ? AND body = ? AND target_url = ?', @tt, @tb, @uri])
    article.destroy if article
  end

  def teardown
    article = Article.find(:first, :conditions => ['title = ? AND body = ? AND target_url = ?', @tt, @tb, @uri])
    article.destroy if article
  end

  def test_atompost
    res = @obj.atompost(@uri, @user, @pass,
                        @tt, @tb, Time.now, 'misc', 'html')
    assert_instance_of(Net::HTTPCreated, res)
  end

  def test_atompost__plain
    res = @obj.atompost(@uri, @user, @pass,
                        @tt, @tb, Time.now, 'misc', 'plain')
    assert_instance_of(Net::HTTPCreated, res)
  end

end
