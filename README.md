## Description

When integrating with QuickBooks Online (QBO) there is one thing you better be prepared for: *errors* and lots of 'em.
The `qbo_rails` gem is a Rails engine that is all about handling and responding to QBO errors. It does some other common things as well such as automatically determining and submitting create or update requests.

The `qbo_rails` gem depends on both the [quickbooks-ruby](https://github.com/ruckus/quickbooks-ruby) and the [quickbooks-ruby-base](https://github.com/minimul/quickbooks-ruby-base). In essence, it is a thin wrapper around the CRUD actions of `quickbooks-ruby`. The `lib/qbo_rails.rb` [source](https://github.com/minimul/qbo_rails/blob/master/lib/qbo_rails.rb) is only ~100 lines of code.

## Version support
- Rails 4
- Ruby 2

## Quick Start Guide
- Add `gem 'qbo_rails'`
- `bundle`
- `bundle exec qbo_rails:install`
  - this creates:
    - `config/initializers/qbo_rails.rb`
    - db migration for the `qbo_errors` table
    - `app/models/qbo_error.rb`
- `bin/rake db:migrate`
- edit `config/secrets.yml` 
```ruby
development: &default
  ...
  qbo_app_consumer_key: <%= ENV['YOUR_QBO_APP_DEV_CONSUMER_KEY'] %>
  qbo_app_consumer_secret: <%= ENV['YOUR_QBO_APP_DEV_CONSUMER_SECRET'] %>
  ...
```
- edit `config/initializers/qbo_rails.rb`
  - Need to [fill in the proper attribute names](https://github.com/minimul/quickbooks-ruby-base#configuration) that are used for persisting the Intuit OAuth credentials.

### Configuration options
The gem assumes that you store QBO ids in a column/attribute called `qbo_id`. You can change that as so:
```ruby
 QboRails.foreign_key = 'qbo_external_id'
```

### Using `QboRails`
#### Usage: `.base()`
The `quickbooks-ruby-base` gem is composed into a new instance of `QboRails` and can accessed as so:

```ruby
    qbo_rails = QboRails.new(account, :customer)
    qbo_rails.base
```
You can access the `quickbooks-ruby` instance through `.base`. See the [docs](https://github.com/minimul/quickbooks-ruby-base).

#### Usage: `.create_or_update()`

You must keep entities in sync between your app and QBO. Using the `create_or_update` method `qbo_rails` will send a `create` or `update` based on if say `customer.qbo_id` is nil. 

Example:
```ruby
    account = Account.find(1) # this is the where the QBO OAuth access_token, secret, and company_id are found
    customer = Customer.find(1)
    qbo_rails = QboRails.new(account, :customer)
    qb_customer = qbo_rails.base.qr_model(:customer)
    qb_customer.display_name = customer.display_name
    address = qbo_rails.base.qr_model(:physical_address)
    address.line1 = customer.address_1
    address.city = customer.city
    address.country_sub_division_code = customer.state
    address.postal_code = customer.zip
    qb_customer.billing_address = address
    qbo_rails.create_or_update(customer, qbo_customer)

```
If `customer.qbo_id` is `nil` then a create request is sent to QBO. If successful the QBO Id for the new Customer record will be automatically recorded in `customer.qbo_id`. Therefore, the next time `qbo_rails.create_or_update(customer, qbo_customer)` for this customer is called an `update` request will be sent. Sending an update first involves querying QBO to get the latest sync token so it is nice to DRY up that procedure.

#### Usage: `.create()`
If you don't need to do an update and don't need to record the QBO Id in a model but still want the error handling goodness then the `create()` method is available

Example:
```ruby
    qbo_rails = QboRails.new(account, :customer)
    qb_customer = qbo_rails.base.qr_model(:customer)
    qb_customer.display_name = 'Hockey Mom'
    qbo_rails.create(qbo_customer)

```

#### Usage: `.delete()`
The `delete` method takes either the ActiveRecord instance or a QBO Id.

Example: This deletes the QBO Customer with Id = 1
```ruby
    qbo_rails = QboRails.new(account, :customer)
    qbo_rails.delete(1)

```

Example: Pass in ActiveRecord instance
```ruby
    customer = account.customers.find(2)
    qbo_rails = QboRails.new(account, :customer)
    qbo_rails.delete(customer)

```


#### Usage: Returned results
Use `qbo_rails.result`. e.g.

```ruby
    qbo_rails.create_or_update(customer, qbo_customer)
    puts qbo_rails.result.id
```

#### Usage: Error handling
QBO API Errors are recorded in the `QboError` model. The column names are:

```ruby

=> QboError(id: integer, 
            message: string, 
            body: text, 
            resource_type: string, 
            resource_id: integer, 
            request_xml: text, 
            created_at: datetime, 
            updated_at: datetime
            )
```

The columns `resource_type` and `resource_id` are for recording the ActiveRecord model and are ready-to-go for polymorphic associations.

#### Usage: Responding to an error
Let's say that you have a customer in Rails, Jane Riley, and you send her in as a create request to QBO. There is already a Jane Riley on QBO. Guess what? `Duplicate Name Exists Error`. But `qbo_rails` can handle this by simple adding the below method with the prefix `handle_error`. 
For example in your Rails app you could add a file in `app/services/qbo_rails/error_handler.rb` that responds to QBO API's `Duplicate Name Exists Error`.

```ruby

class QboRails
  module ErrorHandler

    def handle_error_name_entity_already_exists(exception)
      if exception.message =~ /Duplicate Name Exists Error.*Another (customer|vendor|employee)/m
        display_name = Nokogiri::XML(exception.request_xml).at('DisplayName').content
        result = @base.find_by_display_name(display_name)
        if result.entries.size == 1
          @record.update_column(foreign_key, result.entries.first.id)
          @only_run_once = true
          @record.reload
          create_or_update(@record, @qb_record)
          true
        else
          false
        end
      else
        false
      end
    end

end
```
It catches the error, queries QBO for Jane Riley, sets the customer record with the Id, and then calls `create_or_update`, which will properly send an update request. You have access to all `QboRails` instance variables such as:

```ruby
@record: This is the ActiveRecord instance (only available if passed)
@qb_record: This is the `quickbooks-ruby` instance.
@base: This is the `quickbooks-ruby-base` instance.
```
See the [source](https://github.com/minimul/) to get all the instance vars and methods available to you when crafting custom error handling.

#### Usage: Responding to errors ground rules
1. Always return `true` after you have run a response action.
2. Always set `@only_run_once = true` when returning `true`.
3. If not 1 & 2 always return `false`.

These rules are for preventing infinite looping. See the `spec/dummy` [code](https://github.com/minimul/qbo_rails/blob/master/spec/dummy/app/services/qbo_rails/error_handler.rb) for more examples.

## Contributing

1. Fork it ( https://github.com/minimul/qbo_rails/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Note: If you are going to adding new specs or modify existing ones that involve a transaction with the QBO API then they must be recorded using [VCR](https://github.com/vcr/vcr). To do that set your test QBO app and sandbox credentials in `spec/dummy/.env` file (don't commit this in your PR). The `.env` file should be in this format:
```ruby
export QBO_RAILS_CONSUMER_KEY=
export QBO_RAILS_CONSUMER_SECRET=
export QBO_RAILS_ACCESS_TOKEN=
export QBO_RAILS_ACCESS_TOKEN_SECRET=
export QBO_RAILS_COMPANY_ID=
```

To make it easy to get your OAuth information you can:
1. `cd spec/dummy`
2. `bin/rails s`
3. Goto `localhost:3000`
4. Go through the OAuth process and the `.env` variables for `QBO_RAILS_ACCESS_TOKEN`, `QBO_RAILS_ACCESS_TOKEN_SECRET`, and `QBO_RAILS_COMPANY_ID` will be displayed.

