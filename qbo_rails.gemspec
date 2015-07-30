$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "qbo_rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "qbo_rails"
  s.version     = QboRails::VERSION
  s.authors     = ["Christian Pelczarski"]
  s.email       = ["christian@minimul.com"]
  s.homepage    = "https://github.com/minimul/qbo_rails"
  s.summary     = "Framework for communicating with QuickBooks Online that provides error handling and translation."
  s.description = ""
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 4.2.0"
  s.add_dependency "quickbooks-ruby"
  s.add_dependency "quickbooks-ruby-base"
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'awesome_print'
  s.add_development_dependency 'dotenv'
  s.add_development_dependency 'oauth-plugin'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'vcr'
  s.add_development_dependency "sqlite3"
end
