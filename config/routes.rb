Rails.application.routes.draw do

  get 'dummy', to: 'items#dummy'
  get 'tes', to: 'items#tes'

  # https://developer.chrome.com/multidevice/android/intents
  get "/android/signin/:token/:uid/:userid" => redirect("intent://signinbyoauth/#Intent;scheme=tswork_havings;package=work.t_s.shim0mura.havings;S.token=%{token};S.uid=%{uid};S.userid=%{userid};end"), as: :oauth_android_callback
  get "/ios/signin/:token/:uid/:userid" => redirect("ioshavings://test?token=%{token}&uid=%{uid}&userid=%{userid}"), as: :oauth_ios_callback

  get 'user/self', to: 'user#get_self'
  get 'user/list_tree', to: 'user#list_tree'
  get 'user/:user_id', to: 'user#index', as: :user_page
  get 'user/:user_id/user_items', to: 'user#user_items'
  get 'user/:user_id/item_tree', to: 'user#item_tree'
  get 'user/:user_id/item_images', to: 'user#item_images'
  get 'user/:user_id/favorite_items', to: 'user#favorite_items'
  get 'user/:user_id/favorite_images', to: 'user#favorite_images'
  get 'user/:user_id/dump_items', to: 'user#dump_items'
  get 'user/:user_id/timeline', to: 'user#timeline'
  get 'user/:user_id/following', to: 'user#following'
  get 'user/:user_id/followers', to: 'user#followers'
  post '/user/:user_id/follow', to: 'follows#create'
  delete '/user/:user_id/follow', to: 'follows#destroy'
  get 'user/classed_items/:tag_id', to: 'user#classed_items'

  get 'home', to: 'welcome#home', as: :dashboard
  get 'home/timeline', to: 'welcome#timeline'
  get 'home/graph', to: 'welcome#item_graph'
  get 'home/all_done_task', to: 'welcome#all_done_task'
  get 'home/item_count', to: 'welcome#item_count'
  get 'popular/tag', to: 'welcome#popular_tag'
  get 'popular/list', to: 'welcome#popular_list'
  get 'pickup', to: 'welcome#pickup'

  resources :items
  post '/items/:id/image', to: 'items#add_image'
  put '/items/:id/dump', to: 'items#dump'
  get '/items/:id/next_items', to: 'items#next_items', as: 'next_item'
  get '/items/:id/next_images', to: 'items#next_images'
  get '/items/:id/done_task', to: 'items#done_task'
  get '/items/:id/timeline', to: 'items#timeline'
  get '/items/:id/showing_events', to: 'items#showing_events'
  get '/items/:id/favorite', to: 'favorite#index'
  get '/items/:id/favorited_users', to: 'favorite#favorited_users'
  post '/items/:id/favorite', to: 'favorite#create'
  delete '/items/:id/favorite', to: 'favorite#destroy'
  get '/items/:id/comment', to: 'comments#index'
  post '/items/:id/comment', to: 'comments#create'
  delete '/items/:id/comment/:comment_id', to: 'comments#destroy'
  get '/items/:id/image/:image_id', to: 'items#item_image'
  put '/items/:id/image/:image_id', to: 'items#update_image_metadata'
  delete '/items/:id/image/:image_id', to: 'items#destroy_image'
  get '/items/image/:image_id/favorited_users', to: 'favorite#image_favorited_users'
  post '/items/image/:image_id/favorite', to: 'favorite#image_favorite'
  delete '/items/image/:image_id/favorite', to: 'favorite#image_unfavorite'

  resources :timers, only: [:index, :create, :update, :destroy]
  post '/timers/:id/done', to: 'timers#done', as: :timer_done
  post '/timers/:id/do_later', to: 'timers#do_later'
  post '/timers/:id/end', to: 'timers#end_timer'

  get '/notification', to: 'notifications#index'
  get '/notification/unread_count', to: 'notifications#unread_count'
  put '/notification/read', to: 'notifications#read'

  get '/search/tag/', to: 'search#tag'
  get '/search/user/', to: 'search#user'

  get '/tags/default_tag_migration/', to: 'tags#default_tag_migration'
  get '/tags/tag_migration/:migration_id', to: 'tags#tag_migration'
  get '/tags/current_migration_version/', to: 'tags#tag_migration_version'

  post '/device_token/:type/', to: 'device_tokens#create'
  put '/device_token/:type/', to: 'device_tokens#update'
  put '/device_token/state/:type/:value', to: 'device_tokens#change_state'

  get '/privacy-policy', to: 'welcome#privacy_policy', as: :privacy_policy

  get  'inquiry', to: 'inquiry#index', as: :inquiry
  post 'inquiry/confirm', to: 'inquiry#confirm'
  post 'inquiry/thanks', to: 'inquiry#thanks'

  devise_for :users, controllers: {
    omniauth_callbacks: 'omniauth_callbacks',
    registrations: 'registrations'
  }

  get 'admin/index'
  post 'admin/extract'
  get 'admin/extracted_item'
  post 'admin/type_item'
  get 'admin/tags'

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
