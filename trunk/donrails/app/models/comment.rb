class Comment < ActiveRecord::Base
	has_and_belongs_to_many :articles, :join_table => "comments_articles"
end
