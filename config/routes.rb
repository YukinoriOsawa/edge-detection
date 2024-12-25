Rails.application.routes.draw do
  root 'images#index'
  resources :images, only: [:index, :create] do
    post 'process_edge', on: :collection
  end
end