Rails.application.routes.draw do

  get 'user/:user_id', to: 'user#index', as: :user_page
  get 'user/:user_id/timeline', to: 'user#timeline'
  post '/user/:user_id/follow', to: 'follows#create'
  delete '/user/:user_id/follow', to: 'follows#destroy'

  get 'home', to: 'welcome#home'

  resources :items
  get '/items/:id/done_task', to: 'items#done_task'
  get '/items/:id/timeline', to: 'items#timeline'
  get '/items/:id/favorite', to: 'favorite#index'
  post '/items/:id/favorite', to: 'favorite#create'
  delete '/items/:id/favorite', to: 'favorite#destroy'
  post '/items/:id/comment', to: 'comments#create'
  delete '/items/:id/comment/:comment_id', to: 'comments#destroy'

  resources :timers, only: [:index, :create, :update, :destroy]
  post '/timers/:id/done', to: 'timers#done', as: :timer_done

  put '/notification/read', to: 'notifications#read'

  devise_for :users, controllers: {
    omniauth_callbacks: 'omniauth_callbacks',
    registrations: 'registrations'
  }

  require 'sidekiq/web'
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == 'shimomura' && password == 'tatsuhiko'
  end 
  mount Sidekiq::Web => '/sidekiq'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"

  root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
