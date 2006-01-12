require 'uri'
require 'net/http'

class Ping < ActiveRecord::Base
  belongs_to :article

  def send_ping2(pingurl, title, excerpt)
    uri = URI.parse(pingurl)

    post = "title=#{URI.escape(title)}"
    post << "&excerpt=#{URI.escape(excerpt)}"
    post << "&url=#{URI.escape(self.url)}"
    post << "&blog_name=#{URI.escape(RDF_TITLE)}"

    Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = 10
      response = http.post("#{uri.path}?#{uri.query}", post)
      return response.body
    end 

  end
end
