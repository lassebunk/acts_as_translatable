# class to hold record translations
class RecordTranslation < ActiveRecord::Base
  attr_accessible :content, :translatable_field, :locale
end