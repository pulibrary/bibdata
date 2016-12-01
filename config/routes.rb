Rails.application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  mount Locations::Engine, at: '/locations'

  resources :dump_files, only: [:show]
  resources :events, only: [:show, :index, :destroy]
  resources :dumps, only: [:show]

  get '/bibliographic', to: 'bibliographic#index', defaults: { format: :txt }
  get '/bibliographic/:bib_id', to: 'bibliographic#bib', defaults: { format: :xml }, as: :show_bib
  get '/bibliographic/:bib_id/holdings', to: 'bibliographic#bib_holdings', defaults: { format: :xml }
  get '/bibliographic/:bib_id/jsonld', to: 'bibliographic#bib_jsonld'
  get '/bibliographic/:bib_id/items', to: 'bibliographic#bib_items', defaults: { format: :json }
  get '/bibliographic/:bib_id/solr', to: 'bibliographic#bib_solr'

  get '/holdings', to: 'holdings#index', defaults: { format: :txt }
  get '/holdings/:holding_id', to: 'holdings#holding', defaults: { format: :json }
  get '/holdings/:holding_id/items', to: 'holdings#holding_items', defaults: { format: :json }

  get '/availability', to: 'availability#index', defaults: { format: :json }

  get '/items', to: 'items#index', defaults: { format: :txt }
  get '/items/:item_id', to: 'items#item', defaults: { format: :json }

  get '/barcode', to: 'barcode#index', defaults: {format: :txt }
  get '/barcode/:barcode', to: 'barcode#barcode', defaults: { format: :xml }, as: :show_barcode

  get '/codes/:location', to: 'codes#locations', defaults: { format: :json }
  get '/patron/:patron_id', to: 'patron#patron_info', defaults: { format: :json }
  get '/patron/:patron_id/codes', to: 'patron#patron_codes', defaults: { format: :json }

  get '/courses', to: 'courses#index', defaults: { format: :json }
  get "/bib_ids", to: 'courses#bibs', defaults: { format: :json }
end
