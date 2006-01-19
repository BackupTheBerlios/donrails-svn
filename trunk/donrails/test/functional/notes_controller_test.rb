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


  def test_trackback
    post :trackback,
    :id => 1,
    :title => 'title test util',
    :excerpt => 'excerpt text',
    :url => "http://test.example.com/blog/",
    :blog_name => 'test of donrails'

    require_response_body = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<response>\n  <error>0</error>\n  <message>success</message>\n</response>\n"
    assert_response :success
    # puts @response.body
    assert_equal require_response_body, @response.body
  end

  def test_pick_article_a
    get :pick_article_a, :pickid => 1
#    puts @response.body
    assert_response :success
  end

  def test_catch_ping
    post :catch_ping, :category => 'misc', :blog_name => 'test blog',
    :title => 'test title', :excerpt => 'test excerpt', :url => 'http://localhost/test/blog'
    assert_response :success

    get :catch_ping, :category => 'misc', :blog_name => 'test blog',
    :title => 'test title', :excerpt => 'test excerpt', :url => 'http://localhost/test/blog'
    assert_response 404
  end

  def test_recent_category_title_a
    get :recent_category_title_a, :category => 'donrails'
#    puts @response.body
    assert_response :success
  end

end
