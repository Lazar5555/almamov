Rails.application.routes.draw do
    get "/statistics", to: "welcome#statistics"

    devise_for :users
    
    resources :trips do
      collection do
        post 'import'
        get 'apriori'
        get 'result_apriori'
        get 'dbscan'
        get 'result_dbscan'
      end
    end

    root to: "welcome#index"
  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
