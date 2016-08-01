Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  # get '/sale' => 'home#sale'
  namespace :admin do
    resources :retail do
      collection do
        get :import_customers
        get :import_orders
        get :export_all_orders
        get :export_all_customers
        post :retail_update_order
        post :retail_update_user
        # get :states_connection
        post :update_states
      end
    end
  end
  post '/retail/retail_update_order' => 'retail_callback#retail_update_order'
  post '/retail/retail_update_user' => 'retail_callback#retail_update_user'
end
