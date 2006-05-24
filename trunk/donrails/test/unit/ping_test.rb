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

=begin
  def test_send_ping2
    pingurl = "http://localhost:3000/notes/catch_ping/"
    title = "test title"
    excerpt = "test excerpt"
    rbody = @ping.send_ping2(pingurl, title, excerpt)
    xml = HTree.parse(rbody).to_rexml
    assert_equal('0', xml.elements['response/error'].text)
    begin
      errorurl = "http://localhost:3001/notes/catch_ping/"
      rbody = @ping.send_ping2(errorurl, title, excerpt)
    rescue
      p $!
    end
  end
=end

 def test_truth
   assert_kind_of Ping,  @ping
 end

end
