FactoryGirl.define do
  factory :account do
    company_name 'Nelson Hockey Club'
    qb_token Rails.application.secrets.qbo_sandbox_access_token
    qb_secret Rails.application.secrets.qbo_sandbox_access_token_secret
    qb_company_id Rails.application.secrets.qbo_sandbox_company_id
  end
end
