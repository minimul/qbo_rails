class SettingsController < ApplicationController

  def oauth_start
    token = $qb_oauth_consumer.get_request_token(oauth_callback: oauth_callback_url)
    cache_token(token)
    redirect_to("https://appcenter.intuit.com/Connect/Begin?oauth_token=#{token.token}") and return
  end

  def oauth_callback
    at = cache_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    @url = root_url
    session[:at] = { token: at.token, secret: at.secret, companyid: params['realmId'] }
    msg = "Your QuickBooks account has been successfully linked."
    flash[:notice] = msg
    render 'close_and_redirect'
  rescue => e
    flash[:alert] = "There was a problem linking Your QuickBooks account with error: #{e.message}"
    render 'close_and_redirect'
  end

  private

  def cache_token(value = nil)
    key = "token"
    unless value
      Rails.cache.read(key)
    else
      Rails.cache.write(key, value, expire_in: 1.hour)
    end
  end
end

  
