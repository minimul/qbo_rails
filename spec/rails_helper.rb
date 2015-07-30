# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../dummy/config/environment", __FILE__)
require 'rspec/rails'
require 'factory_girl_rails'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path("../vcr", __FILE__)
  config.hook_into :webmock
  s = Rails.application.secrets
  config.filter_sensitive_data('<ACCESS_TOKEN>') { URI.encode_www_form_component(s.qbo_sandbox_access_token) }
  config.filter_sensitive_data('<CONSUMER_KEY>') { URI.encode_www_form_component(s.qbo_app_consumer_key) }
  config.filter_sensitive_data('<COMPANY_ID>') { URI.encode_www_form_component(s.qbo_sandbox_company_id) }
  
  uri_matcher = VCR.request_matchers[:uri]
  # Don't check sandbox company id or trailing URL id
  # This enables multiple different sandboxes to be used
  # in testing
  config.register_request_matcher(:for_intuit) do |req_1, req_2|
    uri1, uri2 = req_1.uri, req_2.uri
    if uri1 =~ /intuit\.com/ && uri2 =~ /intuit\.com/
      strip_url_company_id(req_1.uri, req_2.uri)
      regexp_trail_id = %r(/\d+/?\z)
      if uri1.match(regexp_trail_id)
        r1_without_id = uri1.gsub(regexp_trail_id, "")
        r2_without_id = uri2.gsub(regexp_trail_id, "")
        uri1.match(regexp_trail_id) && uri2.match(regexp_trail_id) && r1_without_id == r2_without_id
      else
        uri_matcher.matches?(req_1, req_2)
      end
    else
      uri_matcher.matches?(req_1, req_2)
    end
  end

  def strip_url_company_id(*args)
    regexp_company_id = %r((company)/\d+/?)
    args.each do |ref|
      ref.sub!(regexp_company_id, '')
    end
  end
  config.default_cassette_options = { match_requests_on: [:method, :for_intuit] }
end

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.include FactoryGirl::Syntax::Methods

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!
end
