require 'rails_helper'

describe 'QBO request' do

  describe '.create_or_update' do
    it 'for a basic create' do
      account = create(:account)
      record = create(:customer, firstname: 'Edward')
      qbo_rails, qb_customer = map_to_qbo(account, record)
      expect(record.qbo_id).to be_nil
      VCR.use_cassette("qbo_rails/customer/create", record: :none) do
        qbo_rails.create_or_update(record, qb_customer)
        record.reload
        expect(record.qbo_id).to_not be_nil
        expect(qbo_rails.result.sync_token).to eq 0
      end
    end

    it 'for a basic update' do
      account = create(:account)
      # Get the qbo_id from spec above
      record = create(:customer, firstname: 'Edward', qbo_id: 60)
      qbo_rails, qb_customer = map_to_qbo(account, record)
      #Quickbooks.log = true
      VCR.use_cassette("qbo_rails/customer/update", record: :none) do
        result = qbo_rails.create_or_update(record, qb_customer)
        expect(result.sync_token).to be > 0
      end
    end

  end

  describe '.delete' do
    # At this time you can't delete (or really make inactive) builtin entities 
    # in the the sandbox. So it returns a 400, bad request
    it 'a sandbox customer record, Paulsen Medical Supplies, id 18' do
      account = create(:account)
      qbo_rails = QboRails.new(account, :customer)
      #Quickbooks.log = true
      VCR.use_cassette("qbo_rails/customer/delete", record: :none) do
        expect{ result = qbo_rails.delete(18) }.to change{ QboError.count }.by(1)
      end
    end

    it 'deletes a newly created customer' do
        account = create(:account)
        record = create(:customer, firstname: 'Mathis')
        qbo_rails, qb_customer = map_to_qbo(account, record)
        #Quickbooks.log = true
        VCR.use_cassette("qbo_rails/customer/create_and_then_delete", record: :none) do
          qbo_rails.create_or_update(record, qb_customer)
          qbo_rails.delete(record.reload) 
          expect(Nokogiri::XML(qbo_rails.result.to_xml.to_s).at('Active').content).to eq 'false'
        end
    end
  end

  describe QboRails::ErrorHandler do

    # You can see this is error in spec/dummy/app/service/qbo_rails/error_handler.rb
    it 'initial request is an add request for existing customer that fails. Catch error
      and resend request as an update' do
      account = create(:account)
      record = create(:customer)
      qbo_rails, qb_customer = map_to_qbo(account, record)
      expect(record.qbo_id).to be_nil
      #Quickbooks.log = true
      VCR.use_cassette("qbo_rails/customer/error_customer_in_use", record: :none) do
        expect { qbo_rails.create_or_update(record, qb_customer) }.to change{ QboError.count }.by(0)
        record.reload
        expect(record.qbo_id).to_not be_nil
        expect(qbo_rails.result.id).to eq record.qbo_id.to_s
        expect(qbo_rails.error).to be_nil
      end
    end

    it 'does not match a custom error handler and records error' do
      account = create(:account)
      record = create(:customer)
      qbo_rails, qb_customer = map_to_qbo(account, record)
      qb_customer.display_name = 'Emer:Rack'
      #Quickbooks.log = true
      VCR.use_cassette("qbo_rails/customer/error_customer_bad_display_name", record: :none) do
        expect{ qbo_rails.create_or_update(record, qb_customer) }.to change{ QboError.count }.by(1)
        expect(qbo_rails.error).to_not be_nil
      end
    end

    # You can see this is error in spec/dummy/app/service/qbo_rails/error_handler.rb
    it 'runs a custom error handler and verifies that @only_run_once prevents endless looping' do
      account = create(:account)
      account.qb_token = nil
      account.qb_secret = nil
      record = create(:customer)
      qbo_rails, qb_customer = map_to_qbo(account, record)
      expect(qbo_rails.only_run_once).to be nil
      #Quickbooks.log = true
      VCR.use_cassette("qbo_rails/auth/forbidden", record: :none) do
        qbo_rails.create_or_update(record, qb_customer)
        expect(qbo_rails.only_run_once).to be true
      end
    end

  end

  def map_to_qbo(account, record)
    qbo_rails = QboRails.new(account, :customer)
    qb_customer = qbo_rails.base.qr_model(:customer)
    qb_customer.display_name = "#{record.firstname} #{record.lastname}"
    address = qbo_rails.base.qr_model :physical_address
    address.line1 = record.address_1
    address.city = record.city
    address.country_sub_division_code = record.state
    address.postal_code = record.zip
    qb_customer.billing_address = address
    [qbo_rails, qb_customer]
  end
end
