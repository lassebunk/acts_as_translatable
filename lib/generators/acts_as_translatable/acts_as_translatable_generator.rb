require "rails/generators"
require "rails/generators/active_record"

class ActsAsTranslatableGenerator < Rails::Generators::NamedBase
  include Rails::Generators::Migration
  extend ActiveRecord::Generators::Migration
  
  argument :model_name
  argument :columns, :type => :array

  source_root File.expand_path('../templates', __FILE__)
  
  def create_migrations
    migration_template "migration.rb", "db/migrate/#{migration_name}.rb"
  end
  
  def translatable_class
    model_name.classify
  end
  
  def translatable_table
    model_name.tableize.to_sym
  end
  
  def translatable_type
    model_name.camelize
  end
  
  def migration_name
    "translate_#{model_name.tableize}"
  end

  def migration_class_name
    migration_name.camelize
  end
  
  def locale
    file_name
  end
end