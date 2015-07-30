require 'quickbooks-ruby'
require 'quickbooks-ruby-base'
require_relative 'qbo_rails/error_handler'
class QboRails
  attr_accessor :error, :only_run_once
  attr_reader   :result, :base
  cattr_accessor(:foreign_key) { "qbo_id" }

  include ActiveSupport::Rescuable
  include ErrorHandler
  rescue_from Quickbooks::IntuitRequestException, 
              Quickbooks::InvalidModelException, 
              Quickbooks::AuthorizationFailure, 
              Quickbooks::Forbidden, 
              Quickbooks::MissingRealmError, with: :record_error

  def initialize(account, type = nil)
    @base = Quickbooks::Base.new(account, type) 
  end

  def create(qb_record)
    with_rescued_exception do
      @qb_record = qb_record
      @result = @base.service.create(@qb_record)
      @result
    end
  end

  def create_or_update(record, qb_record)
    with_rescued_exception do
      @record = record
      @qb_record = qb_record
      if id = @record.send(foreign_key)
        prepare_update(id, qb_record)
        @result = @base.service.update(qb_record)
      else
        @result = @base.service.create(@qb_record)
        set_qbo_id
      end
    end
  end

  def delete(record_or_qbo_id)
    with_rescued_exception do
      id = record_or_qbo_id.try(foreign_key) || record_or_qbo_id
      @qb_record = @base.find_by_id(id)
      @result = @base.service.delete(@qb_record)
    end
  end

  protected

  def with_rescued_exception
    yield
  rescue => e
    if @only_run_once
      rescue_with_handler(e) || raise
    else
      unless run_error_handlers(e)
        rescue_with_handler(e) || raise
      end
    end
  end

  def run_error_handlers(e)
    methods.detect do |method|
      if method =~ /^handle_error_/
        send(method, e)
      end
    end
  end

  def qbo_error_params(exception)
    @error = {
      message: exception.message[0..250],
      body: "#{exception}\n\n#{exception.message}\n\n#{exception.backtrace}",
      resource_type: @record.try(:class).try(:name),
      resource_id: @record.try(:id),
      request_xml: request_xml(exception)
    }    
  end

  def record_error(exception)
    QboError.create!(qbo_error_params(exception))
  end

  def request_xml(exception)
    if exception.respond_to?(:request_xml)
      exception.request_xml
    elsif defined?(@qb_record)
      @qb_record.to_xml.to_s
    end
  end

  def prepare_update(id, qb_record)
    result = @base.find_by_id(id)
    qb_record.id = result.id
    qb_record.sync_token = result.sync_token
    qb_record
  end

  def set_qbo_id
    @record.update(self.foreign_key => @result.id)
    @record
  end
end
