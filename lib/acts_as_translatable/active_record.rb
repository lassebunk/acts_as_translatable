class ActiveRecord::Base
  def self.acts_as_translatable_on(*fields)
    eval "class ::#{name}
            after_save :save_translations
            after_destroy :destroy_record_translations
            
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
              # delete all previous translations of this record
              destroy_record_translations
              
              # loop through updated translations
              translations.each_pair do |locale, fields|
                fields.each_pair do |field, content|
                  # create translation record
                  RecordTranslation.create :translatable_id => id, :translatable_type => self.class.name, :translatable_field => field, :locale => locale.to_s, :content => content unless content.blank?
                end
              end
            end
            
            def destroy_record_translations
              # delete all translations of this record
              record_translations.destroy_all
            end
          end"  
    fields.each do |field|
      eval "class ::#{name}
              def #{field}
                # get I18n fallbacks
                if I18n.respond_to?(:fallbacks)
                  locales = I18n.fallbacks[I18n.locale]
                else
                  locales = [I18n.locale]
                end
                
                # fallbacks
                locales.each do |locale|
                  if fields = translations[locale]
                    content = fields[\"#{field}\"]
                    return content if content
                  end
                end
                
                # none found
                return nil
              end

              def #{field}?
                !#{field}.blank?
              end

              def #{field}=(value)
                translations[I18n.locale] ||= {}
                translations[I18n.locale][\"#{field}\"] = value
              end
            end"  
    end
  end
end

