require 'digest/sha1'
require '/usr/share/rails/activerecord/lib/active_record'
require 'yaml'
 
fconf = open("#{ENV['HOME']}/.donrails/atomcheck.yml", "r")
conf = YAML::load(fconf)

=begin rdoc

Example of ~/.donrails/atomcheck.yml

* Example1

dbfile: /home/user/.donrails/data.db
adapter: sqlite

* Example2

adapter: postgresql
database: donrails
host: localhost
username: donrailuser
password: donrailpassword

=end

ActiveRecord::Base.establish_connection(conf)

class Article < ActiveRecord::Base
end

class AtomStatus
  def initialize
  end

  def check(target_url, title, body, check=true)
    aris = Article.find(:first, :conditions => ["target_url = ? AND title = ? AND body = ?", target_url, title, body])
    if (aris and aris.status == 201)
      return 0 
    end
    aris2 = Article.new("target_url" => target_url, "title" => title, "body" => body)
    aris2.save
    return aris2.id
  end

  def update(id, status, check=true)
    if check
      aris = Article.find(id)
      aris.status = status
      aris.save
    end
  end

end
