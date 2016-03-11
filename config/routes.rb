Rails.application.routes.draw do
  resources :users
  resources :users
  match '/404' => 'errors#error404', via: [:get, :post, :patch, :delete]

  namespace :api do
    namespace :v1 do
      resources :users, only: [:create]
      resources :vices, only: [:index]
      # resources :accounts, except: [:index, :new, :edit]
      # resources :banks, except: [:index, :new, :edit]

      # Calls that do not requre an access token
      get  '/'               => 'api#request_get'
      post '/'               => 'api#request_post'
      get  'auth'            => 'api#auth'
      post 'confirmation'    => 'api#confirmation'
      get  'check_email'     => 'api#check_email'
      get  'twilio_callback' => 'api#twilio_callback'
      scope 'version' do
        get 'ios' => 'api#version_ios'
      end

      # Model-specific calls (other than those created by resources)
      scope 'users' do
        scope 'me' do
          get  '/'                    => 'users#get_me'
          put  '/'                    => 'users#update_me'
          put  'vices'                => 'users#set_vices'
          get  'account_connect'      => 'users#account_connect'
          get  'account_mfa'          => 'users#account_mfa'
          put  'remove_accounts'      => 'users#remove_accounts'
          get  'refresh_transactions' => 'users#refresh_transactions' # TODO: Document
          post 'dev_deduct'           => 'users#dev_deduct' # TODO: Document
        end
      end
      scope 'transactions' do
        scope ':id' do
          post 'back_out' => 'transactions#back_out' # TODO: Document, test
        end
      end
    end
  end
end
