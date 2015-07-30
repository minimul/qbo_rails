require 'rails/generators'
require 'rails/generators/active_record'

class QboRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      extend Rails::Generators::Migration

      namespace "qbo_rails:install"
      desc "Copy QboRails default files"
      source_root File.expand_path('../templates', __FILE__)
      
      def copy_config
         template('config/qbo_rails.rb', "config/initializers/qbo_rails.rb")
      end

      def copy_model
         template('models/qbo_error.rb', "app/models/qbo_error.rb")
      end

      def active_record
        migration_template 'db/migrate/create_qbo_errors.rb', 'db/migrate/create_qbo_errors.rb'
      end

      def self.next_migration_number(dirname)
        ::ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

    end
  end
end
