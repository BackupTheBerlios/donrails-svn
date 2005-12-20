class Category < ActiveRecord::Base
	has_and_belongs_to_many :articles, :join_table => "categories_articles"
end
