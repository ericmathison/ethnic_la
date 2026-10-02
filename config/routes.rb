Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  devise_for :admins

  # Health check used by Kamal to verify the app booted
  get 'up' => 'rails/health#show', as: :rails_health_check

  root 'ethnic_churches#index'

  get 'languages/:id' => 'languages#show', as: :language
  get 'attributions' => 'pages#attributions', as: :attributions

  resources :ethnic_churches
  resources :religions, only: %i[index show]
  resources :school_languages, path: 'language-map', only: %i[index show]
  resources :ethnicities, path: 'ethnicity-map', only: %i[index show]
end
