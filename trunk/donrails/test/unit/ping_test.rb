require File.dirname(__FILE__) + '/../test_helper'

require 'rexml/document'
require 'htree'

class PingTest < Test::Unit::TestCase
  fixtures :pings, :articles

  def setup
    @ping = Ping.new
#    unless @ping.article_id
#     @ping.article_id = 4846
#    end
#    unless @ping.url
#      @ping.url = "http://192.168.4.2:3000/notes/id/4846"
#    end
#    @ping.save
  end

  def test_send_ping2
    @ping1 = Ping.find(1)
    pingurl = "http://localhost:3000/notes/catch_ping/"
    title = "test title"
    excerpt = "test excerpt"
    rbody = @ping1.send_ping2(pingurl, title, excerpt)
    xml = HTree.parse(rbody).to_rexml
    assert_equal('0', xml.elements['response/error'].text)
  end


  def test_truth
    assert_kind_of Ping,  @ping
  end

end
