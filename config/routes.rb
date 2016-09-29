Rails.application.routes.draw do
  namespace :v1 do
    resources :users, only: [:create]
    resources :vices, only: [:index]

    # Calls that do not requre an access token
    get  '/'                        => 'api#request_get'
    post '/'                        => 'api#request_post'
    get  'auth'                     => 'api#auth'
    post 'reset_password'           => 'api#reset_password'
    put  'update_password'          => 'api#update_password'
    get  'check_email'              => 'api#check_email'
    post 'weekly_deduct_cron'       => 'api#weekly_deduct_cron'
    post 'transaction_refresh_cron' => 'api#transaction_refresh_cron'
    get  'dev_ratelimit'            => 'api#dev_ratelimit'
    scope 'version' do
      get 'ios' => 'api#version_ios'
    end

    scope 'webhooks' do
      get  'twilio' => 'webhooks#twilio'
      get  'plaid'  => 'webhooks#plaid'
      post 'dwolla' => 'webhooks#dwolla'
    end


    # Model-specific calls (other than those created by resources)
    scope 'users' do
      scope 'me' do
        get    '/'                        => 'users#get_me'
        put    '/'                        => 'users#update_me'
        get    'yearly_fund'              => 'users#get_yearly_fund'
        put    'vices'                    => 'users#set_vices'
        put    'address'                  => 'users#set_address'
        get    'account_connect'          => 'users#account_connect'
        get    'account_mfa'              => 'users#account_mfa'
        put    'accounts'                 => 'users#update_accounts'
        delete 'accounts'                 => 'users#remove_accounts'
        post   'refresh_transactions'     => 'users#refresh_transactions'
        post   'register_push_token'      => 'users#register_push_token'
        post   'dwolla'                   => 'users#dwolla'
        post   'support'                  => 'users#support'
        post   'dev_refresh_transactions' => 'users#dev_refresh_transactions'
        post   'dev_populate'             => 'users#dev_populate'
        post   'dev_deduct'               => 'users#dev_deduct'
        post   'dev_aggregate'            => 'users#dev_aggregate'
        post   'dev_notify'               => 'users#dev_notify'
        post   'dev_email'                => 'users#dev_email'
      end
    end
    scope 'transactions' do
      scope ':id' do
        post 'back_out' => 'transactions#back_out'
        post 'restore'  => 'transactions#restore'
      end
    end
  end
end
