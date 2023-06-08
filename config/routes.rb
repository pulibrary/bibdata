require 'sidekiq/pro/web'
Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  resources :dump_files, only: [:show]
  resources :events, only: [:show, :index, :destroy]
  resources :dumps, only: [:show]
  resources :campus_access_exceptions, only: [:new, :create]

  scope :locations do
    resources :holding_locations
    resources :libraries
    resources :delivery_locations
    get 'digital_locations', to: 'delivery_locations#digital_locations'
  end

  get '/bibliographic', to: 'bibliographic#index', defaults: { format: :txt }
  get '/bibliographic/:bib_id/availability', to: 'bibliographic#availability'
  get '/bibliographic/availability', to: 'bibliographic#availability_many'
  get '/bibliographic/:bib_id/holdings/:holding_id/availability', to: 'bibliographic#availability_holding'
  get '/bibliographic/:bib_id', to: 'bibliographic#bib', defaults: { format: :xml }, as: :show_bib
  get '/bibliographic/:bib_id/solr', to: 'bibliographic#bib_solr'
  get '/bibliographic/:bib_id/holdings', to: 'bibliographic#bib_holdings', defaults: { format: :xml }
  get '/bibliographic/:bib_id/items', to: 'bibliographic#bib_items', defaults: { format: :json }
  get '/availability', to: 'availability#index', defaults: { format: :json }

  get '/barcode', to: 'barcode#index', defaults: { format: :txt }
  get '/barcode/:barcode/scsb', to: 'barcode#scsb', defaults: { format: :xml }

  get '/patron/:patron_id', to: 'patron#patron_info', format: false, defaults: { format: :json }, constraints: { patron_id: /[^\/]+/ }

  get "/campus_access", to: 'campus_access#index', defaults: { format: :csv }

  # deprecated endpoints
  get '/barcode/:barcode', to: 'deprecated_endpoints#gone'
  get '/codes/:location', to: 'deprecated_endpoints#gone'
  get '/holdings', to: 'deprecated_endpoints#gone'
  get '/holdings/:holding_id', to: 'deprecated_endpoints#gone'
  get '/holdings/:holding_id/items', to: 'deprecated_endpoints#gone'
  get '/items', to: 'deprecated_endpoints#gone'
  get '/items/:item_id', to: 'deprecated_endpoints#gone'
  get '/patron/:patron_id/codes', to: 'deprecated_endpoints#gone', constraints: { patron_id: /[^\/]+/ }
  get '/courses', to: 'deprecated_endpoints#gone'
  get '/bib_ids', to: 'deprecated_endpoints#gone'
  post '/bibliographic/:mms_id/holdings/:holding_id/items/:item_pid/discharge', to: 'bibliographic#item_discharge', defaults: { format: :json }
  post '/bibliographic', to: 'bibliographic#update'

  require 'sidekiq/web'
  authenticate :user, ->(user) { user.catalog_admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
end
