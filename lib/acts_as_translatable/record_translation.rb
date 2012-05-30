# class to hold record translations
class RecordTranslation < ActiveRecord::Base
  attr_accessible :translatable_id, :translatable_type, :translatable_field, :locale, :content
end