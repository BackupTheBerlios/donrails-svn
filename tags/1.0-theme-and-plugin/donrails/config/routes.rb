ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  map.connect '', :controller => "notes", :action => "index"

  map.connect "notes/", :controller => "notes", :action => "index"

  map.connect "notes/d/", :controller => "notes", :action => "noteslist"

  map.connect "notes/d/:category", :controller => "notes", 
  :action => "show_category_noteslist",
  :requirements => { 
	:category => /\w+/,
  }
  

  map.connect "notes/:year/:month/:day", :controller => "notes", 
  :action => "show_date",
  :requirements => { 
    :year => /(19|20)\d\d/,
    :month => /[01]?\d/,
    :day => /[0-3]?\d/
  }
#  :day => nil,
#  :month => nil

  map.connect "notes/:year/:month", :controller => "notes", 
  :action => "show_month",
  :requirements => { 
    :year => /(19|20)\d\d/,
    :month => /[01]?\d/,
  }

  map.connect "notes/hnf/:year/:month/:day", :controller => "notes", 
  :action => "hnf_save_date",
  :requirements => { 
    :year => /(19|20)\d\d/,
    :month => /[01]?\d/,
    :day => /[0-3]?\d/
  }

  map.connect "notes/id/:id", :controller => "notes", 
  :action => "show_title",
  :requirements => { 
    :id => /\d+/
  }

  map.connect "notes/t/:title", :controller => "notes", 
  :action => "show_title",
  :requirements => { 
    :title => /\S+/
  }


#   map.connect "notes/afterday/", :controller => "notes", 
#   :action => "afterday"

  map.connect "notes/category/:category", :controller => "notes", 
  :action => "show_category"

  map.connect "notes/:nums", :controller => "notes", 
  :action => "parse_nums",
  :requirements => { 
    :nums => /(\d|-)+/
  }

  map.connect "notes/:nums", :controller => "notes", 
  :action => "indexabc",
  :requirements => { 
    :nums => /\d+(a|b|c).html/
  }

  map.connect "notes/:nums", :controller => "notes", 
  :action => "parse_nums",
  :requirements => { 
    :nums => /\S+.html/
  }

  map.connect "notes/every_year/:month/:day", :controller => "notes", 
  :action => "show_nnen",
  :requirements => { 
    :month => /[01]?\d/,
    :day => /[0-3]?\d/
  }

  map.connect "notes/search/:q", :controller => "notes", 
  :action => "search",
  :requirements => { 
	:q => /\w+/
  }

  map.connect "notes/di.cgi", :controller => "notes", :action => "rdf_recent"

  map.connect "notes/rdf_category/:category", :controller => "notes", 
  :action => "rdf_category",
  :requirements => { 
	:category => /\w+/
  }

  map.connect "notes/rdf_search/:q", :controller => "notes", 
  :action => "rdf_search",
  :requirements => { 
	:q => /\w+/
  }

  # Here's a sample route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  map.connect '', :controller => "notes"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
end
