Rails.application.routes.draw do
  match '/404' => 'errors#error404', via: [:get, :post, :patch, :delete]

  namespace :api do
    namespace :v1 do
      resources :users, except: [:index, :create, :new, :edit]
      resources :accounts, except: [:index, :new, :edit]
      resources :banks, except: [:index, :new, :edit]

      # Calls that do not requre an access token
      get  '/'               => 'api#request_get'
      post '/'               => 'api#request_post'
      get  'auth'            => 'api#auth'
      post 'confirmation'    => 'api#confirmation'
      post 'signup'          => 'api#signup'
      get  'version/ios'     => 'api#version_ios'
      get  'twilio_callback' => 'api#twilio_callback'

      # Calls that require an access token
      get 'test' => 'api#test' # A test call to verify you are authenticated
    end
  end
end
