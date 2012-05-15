class ActiveRecord::Base
  def self.acts_as_translatable_on(*fields)
    fields.each do |field|
      eval "class ::#{name}
              after_save :save_translations
              
              def #{field}
                translations[I18n.locale] ||= {}
                translations[I18n.locale][\"#{field}\"] || nil
              end

              def #{field}=(value)
                translations[I18n.locale] ||= {}
                translations[I18n.locale][\"#{field}\"] = value
              end

              def translations
                unless @translations
                  @translations = {}
                  record_translations.each do |translation|
                    @translations[translation.locale.to_sym] ||= {}
                    @translations[translation.locale.to_sym][translation.translatable_field] = translation.content
                  end
                end
                @translations
              end

              def record_translations
                @record_translations ||= RecordTranslation.where(:translatable_id => id, :translatable_type => self.class.name)
              end
            
              def save_translations
                # delete all previous record translations
                record_translations.destroy_all

                # loop through updated translations
                translations.each_pair do |locale, fields|
                  fields.each_pair do |field, content|
                    # create translation record
                    RecordTranslation.create :translatable_id => id, :translatable_type => self.class.name, :translatable_field => field, :locale => locale.to_s, :content => content unless content.blank?
                  end
                end
              end
            end"  
    end
  end
end

