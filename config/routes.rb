Rails.application.routes.draw do
  authenticate :user do
    root to: 'dashboards#index', as: :authenticated_root
    get 'dashboard', to: 'dashboards#index', as: 'dashboard'
    post 'search', to: 'dashboards#search', defaults: { format: :js }
    resources :pregnancies, only: [ :edit, :update ] do
      # member do
        resources :calls, only: [ :create ]
        resources :notes, only: [ :create, :update ]
      # end
    end
    resources :patients, only: [ :create ]
    patch 'users/:user_id/add_pregnancy/:id', to: 'users#add_pregnancy', as: 'add_pregnancy', defaults: { format: :js }
    patch 'users/:user_id/remove_pregnancy/:id', to: 'users#remove_pregnancy', as: 'remove_pregnancy', defaults: { format: :js }
  end
  root :to => redirect('/users/sign_in')
  devise_for :users
end
