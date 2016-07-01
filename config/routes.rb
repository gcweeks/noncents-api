Rails.application.routes.draw do
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
      get  'check_email'     => 'api#check_email'
      get  'twilio_callback' => 'api#twilio_callback'
      get  'plaid_callback'  => 'api#plaid_callback'
      post 'deduct_cron'     => 'api#deduct_cron'
      post 'test_cron'       => 'api#test_cron'
      scope 'version' do
        get 'ios' => 'api#version_ios'
      end

      # Model-specific calls (other than those created by resources)
      scope 'users' do
        scope 'me' do
          get  '/'                        => 'users#get_me'
          put  '/'                        => 'users#update_me'
          get  'yearly_fund'              => 'users#get_yearly_fund'
          put  'vices'                    => 'users#set_vices'
          get  'account_connect'          => 'users#account_connect'
          get  'account_mfa'              => 'users#account_mfa'
          put  'remove_accounts'          => 'users#remove_accounts'
          post 'refresh_transactions'     => 'users#refresh_transactions'
          post 'dev_refresh_transactions' => 'users#dev_refresh_transactions'
          post 'dev_populate'             => 'users#dev_populate'
          post 'dev_deduct'               => 'users#dev_deduct'
          post 'dev_aggregate'            => 'users#dev_aggregate'
        end
      end
      scope 'transactions' do
        scope ':id' do
          post 'back_out' => 'transactions#back_out'
          post 'invest'   => 'transactions#invest'
        end
      end
    end
  end
end
