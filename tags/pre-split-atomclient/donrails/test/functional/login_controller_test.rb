require File.dirname(__FILE__) + '/../test_helper'
require 'login_controller'

# Re-raise errors caught by the controller.
class LoginController; def rescue_action(e) raise e end; end

class LoginControllerTest < Test::Unit::TestCase
  def setup
    @controller = LoginController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
#  def test_truth
#    assert true
#  end

  def test_delete_trackback
    get :delete_trackback,
    :deleteid => {'1' => 1}
    puts @response.body
    assert_response 302
  end
end
