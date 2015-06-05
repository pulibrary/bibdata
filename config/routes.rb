Rails.application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  mount Locations::Engine, at: '/locations'

  authenticate :user do
    Locations::Engine.routes.prepend do
      resources :hours_locations, path_names: { new: "create" }, only: [:new, :create, :edit, :update, :destroy]
      resources :holding_locations, path_names: { new: "create" }, only: [:new, :create, :edit, :update, :destroy]
      resources :libraries, path_names: { new: "create"}, only: [:new, :create, :edit, :update, :destroy]
      resources :delivery_locations, path_names: { new: "create"}, only: [:new, :create, :edit, :update, :destroy]
    end
  end

  resources :dump_files, only: [:show]
  resources :events, only: [:show, :index, :destroy]
  resources :dumps, only: [:show]

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
