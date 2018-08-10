Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  devise_for :admins

  root 'ethnic_churches#index'

  get 'languages/:id' => 'languages#show', as: :language
  get 'attributions' => 'pages#attributions', as: :attributions

  resources :ethnic_churches
end
