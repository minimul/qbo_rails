Rails.application.routes.draw do
  get '/oauth_start', to: 'settings#oauth_start'
  get '/oauth_callback', to: 'settings#oauth_callback'
  root to: 'settings#index'
end
