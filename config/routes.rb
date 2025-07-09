require 'sidekiq/pro/web'
Rails.application.routes.draw do
  mount Flipflop::Engine => '/flipflop'
  mount HealthMonitor::Engine, at: '/'
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions' }
  resources :dump_files, only: [:show]
  resources :events, only: %i[show index destroy]
  resources :dumps, only: [:show]

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

  get '/barcode/:barcode/scsb', to: 'barcode#scsb', defaults: { format: :xml }

  get '/patron/:patron_id', to: 'patron#patron_info', format: false, defaults: { format: :json },
                            constraints: { patron_id: %r{[^/]+} }

  require 'sidekiq/web'
  authenticate :user, ->(user) { user.catalog_admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
end
