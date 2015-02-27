Rails.application.routes.draw do

  # TODO: need a dumps controller.
  # /events lists dumps, a single dump is a list of dump files

  # resources :dump_files
  get '/dump_files/:id', to: 'dump_files#show' #, defaults: { format: :json }

  # resources :events
  get '/events/', to: 'events#index' #, defaults: { format: :html }
  get '/events/:id', to: 'events#show' #, defaults: { format: :html }

  get '/bibliographic', to: 'bibliographic#index', defaults: { format: :txt }
  get '/bibliographic/:bib_id', to: 'bibliographic#bib', defaults: { format: :xml }
  get '/bibliographic/:bib_id/holdings', to: 'bibliographic#bib_holdings', defaults: { format: :xml }
  get '/bibliographic/:bib_id/items', to: 'bibliographic#bib_items', defaults: { format: :json }

  get '/holdings', to: 'holdings#index', defaults: { format: :txt }
  get '/holdings/:holding_id', to: 'holdings#holding', defaults: { format: :json }
  get '/holdings/:holding_id/items', to: 'holdings#holding_items', defaults: { format: :json }

  get '/items', to: 'items#index', defaults: { format: :txt }
  get '/items/:item_id', to: 'items#item', defaults: { format: :json }

  get '/codes/:location', to: 'codes#locations', defaults: { format: :json }

end
