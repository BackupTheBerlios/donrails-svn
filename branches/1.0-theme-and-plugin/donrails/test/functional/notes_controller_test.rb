require File.dirname(__FILE__) + '/../test_helper'
require 'notes_controller'

# Re-raise errors caught by the controller.
class NotesController; def rescue_action(e) raise e end; end

class NotesControllerTest < Test::Unit::TestCase
  def setup
    @controller = NotesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


#   def test_trackback
#     post :trackback,
#     :id => 1,
#     :title => 'title test util',
#     :excerpt => 'excerpt text',
#     :url => "http://test.example.com/blog/",
#     :blog_name => 'test of donrails'

#     require_response_body = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<response>\n  <error>0</error>\n  <message>success</message>\n</response>\n"
#     assert_response :success
#     # puts @response.body
#     assert_equal require_response_body, @response.body
#   end

  def test_index
    get :index
    assert_response :success
  end

  def test_search
    get :search, :q => 'sendmail'
    assert_response :success
  end

  def test_show_search_noteslist
    get :search, :q => 'sendmail'
    assert_response :success
  end
  

  def test_pick_article_a
    get :pick_article_a, :pickid => 1
    assert_response :success
  end
  def test_pick_article_a2
    get :pick_article_a2, :pickid => 1
    assert_response :success
  end
  def test_comment_form_a
    get :comment_form_a, :id => 1
    assert_response :success
  end
  def test_articles_long
    get :articles_long
    assert_response :success
  end
  def test_indexabc
    get :indexabc, :nums => '200401a'
    assert_response 302
    assert_equal('http://test.host/notes/tendays?day=01&month=01&year=2004', @response.headers['location'])
    get :indexabc, :nums => '200401b'
    assert_response 302
    assert_equal('http://test.host/notes/tendays?day=11&month=01&year=2004', @response.headers['location'])
    get :indexabc, :nums => '200401c'
    assert_response 302
    assert_equal('http://test.host/notes/tendays?day=21&month=01&year=2004', @response.headers['location'])

    get :indexabc, :nums => '20040105c'
    assert_response 404
  end

  def test_dateparse
  end

  def test_noteslist
    get :noteslist
    assert_response 200
  end

  def test_parse_nums
    get :parse_nums
    assert_response 302

    get :parse_nums, :nums => '200403051'
    assert_response 302
#    puts @response.body
    assert_equal('http://test.host/notes/d?notice=200403051', @response.headers['location'])

    get :parse_nums, :nums => '20040305'
    assert_response 302
#    puts @response.body
    assert_equal('http://test.host/notes/2004/03/05', @response.headers['location'])

    get :parse_nums, :nums => '2004-03-05'
    assert_response 302
#    puts @response.body
    assert_equal('http://test.host/notes/2004/03/05', @response.headers['location'])

    get :parse_nums, :nums => '2004-3-05'
    assert_response 302
#    puts @response.body
    assert_equal('http://test.host/notes/2004/3/05', @response.headers['location'])

    get :parse_nums, :nums => '20040305.html'
    assert_response 302
#    puts @response.body
    assert_equal('http://test.host/notes/2004/03/05', @response.headers['location'])
    get :parse_nums, :nums => '2004-03-05.html'
    assert_response 302
#    puts @response.body
    assert_equal('http://test.host/notes/2004/03/05', @response.headers['location'])
  end

  def test_rdf_recent
    get :rdf_recent
    assert_response :success
  end

  def test_rdf_article
    get :rdf_article, :id => 1
    assert_response :success
  end

  def test_rdf_search
    get :rdf_search, :q => 'sendmail'
    assert_response :success
  end

  def test_rdf_category
    get :rdf_category, :category => 'no category'
    assert_response 302

    get :rdf_category, :category => 'misc'
    assert_response :success
  end

  def test_recent_trigger_title_a
    get :recent_trigger_title_a, :trigger => 'recents'
    assert_response :success
    get :recent_trigger_title_a, :trigger => 'trackbacks'
    assert_response :success
    get :recent_trigger_title_a, :trigger => 'comments'
    assert_response :success
    get :recent_trigger_title_a, :trigger => 'long'
    assert_response :success
  end

  def test_recent_category_title_a
    get :recent_category_title_a, :category => 'misc'
    assert_response :success

    get :recent_category_title_a, :category => 'null'
    assert_response :success
  end

  def test_category_select_a
    get :category_select_a
    assert_response :success
  end

  def test_show_month 
    get :show_month ,:year => 1989, :month => 01
#    p @response.headers
    assert_response 404
  end
  def test_show_month__2
    get :show_month ,:year => 2004, :month => 01
    assert_response 200
  end
  def test_show_month__3
    get :show_month ,:day => 31, :month => 01
#    p @response.headers
    assert_response 404
    get :show_month , :month => 01
#    p @response.headers
    assert_response 404
  end

  def test_show_nnen
    get :show_nnen ,:day => 31, :month => 01
#    p @response.headers
    assert_response 200
  end

  def test_show_date
    get :show_date ,:day => 31, :month => 01, :year => 2002
#    p @response.headers
    assert_response 200
  end
  def test_show_date__2
    get :show_date ,:day => 31, :month => 01, :year => 2009
#    p @response.headers
    assert_response 302
  end


  def test_show_title
    get :show_title, :id => 1
    assert_response 200
  end 
  def test_show_title__2
    get :show_title, :pickid => 2
    assert_response 302
  end 
  def test_show_title__3
    get :show_title, :title => 'MS spam'
    assert_response 302
  end 
  def test_show_title__4
    get :show_title, :id =>10000
    assert_response 404
  end
  def test_show_title__5
    get :show_title
    assert_response 404
  end
  def test_show_title__6
    get :show_title, :inchiki => nil
    assert_response 404
  end


  def test_show_category
    get :show_category, :category => 'misc'
    assert_response 200
  end
  def test_show_category__2
    get :show_category, :category => 'miscmisc'
    assert_response 404
  end
  def test_show_category__3
    get :show_category, :cat => 'nil'
    assert_response 404
  end
  def test_show_category_noteslist
    get :show_category_noteslist, :category => 'misc'
    assert_response 200
  end
  def test_show_category_noteslist__2
    get :show_category_noteslist, :category => 'miscmisc'
    assert_response 404
  end
  def test_show_category_noteslist__3
    get :show_category_noteslist, :catgory => 'miscmisc'
    assert_response 404
  end

  def test_afterday
    get :afterday, :ymd2 => '2005-12-05'
    assert_response 200
  end
  def test_afterday__2
    get :afterday, :ymd2 => '2006-12-05'
    assert_response 404
  end

  def test_tendays
    get :tendays, :ymd2 => '2005-12-05'
    assert_response 200
  end
  def test_tendays__2
    get :tendays, :ymd2 => '2007-12-05'
    assert_response 404
  end

  def test_add_comment2
    c = {"author" => "testauthor", "password" => "hoge", 
      "url" => "http://localhost/test.html", 
      "title" => "testtitle", 
      "body" => "testbody", "article_id" => 1}

    get :add_comment2, :comment => c
    assert_equal('http://test.host/notes/id/1', @response.headers['location'])
    assert_response 302
  end
  def test_add_comment2__2
    c = {"author" => "testauthor", "password" => "hoge", 
      "url" => "http://localhost/", 
      "title" => "testtitle", 
      "body" => "testbody", "article_id" => 11}

    get :add_comment2, :comment => c
    assert_equal('http://test.host/notes/d', @response.headers['location'])
    assert_response 302
  end

  def test_trackback
  end

  ###
  def test_noteslist
    get :noteslist
    assert_response :success
  end

  def test_catch_ping
    post :catch_ping, :category => 'misc', :blog_name => 'test blog',
    :title => 'test title', :excerpt => 'test excerpt', :url => 'http://localhost/test/blog'
    assert_response :success
  end

  def test_recent_category_title_a
    get :recent_category_title_a, :category => 'donrails'
#    puts @response.body
    assert_response :success
  end

end
