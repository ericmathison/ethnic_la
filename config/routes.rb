Rails.application.routes.draw do
  devise_for :admins
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'ethnic_churches#index'

  get 'languages/:id' => 'languages#show', as: :language
  get 'ethnic_churches/:id' => 'ethnic_churches#show', as: :ethnic_church
end
