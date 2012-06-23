module ActsAsTranslatable
  module ClassMethods
    def acts_as_translatable_on(*fields)
      after_initialize :translations
      after_save :save_translations
      has_many :record_translations, :foreign_key => :translatable_id, :conditions => { :translatable_type => name}, :dependent => :destroy
      default_scope :include => :record_translations
      
      # loop through fields to define methods such as "name", "description", and "find_by_name"
      fields.each do |field|
        define_method "#{field}" do
          get_field_content(I18n.locale, field)
        end
        
        define_method "#{field}?" do
          !send("#{field}").blank?
        end
        
        define_method "#{field}=" do |content|
          set_field_content(I18n.locale, field, content)
        end
        
        # loop through fields to define methods such as "name_en", "name_es", and "find_by_name_en"
        I18n.available_locales.each do |locale|
          define_method "#{field}_#{locale}" do
            get_field_content(locale, field)
          end
          
          define_method "#{field}_#{locale}?" do
            !send("#{field}_#{locale}").blank?
          end
          
          define_method "#{field}_#{locale}=" do |content|
            set_field_content(locale, field, content)
          end
        end
      end

      define_method :translations do
        # load translations
        unless @translations
          @translations = {}
          I18n.available_locales.each do |locale|
            @translations[locale] ||= {}
          end
          record_translations.each do |translation|
            @translations[translation.locale.to_sym] ||= {}
            @translations[translation.locale.to_sym][translation.translatable_field.to_sym] = translation.content
          end
        end
        @translations
      end

      define_method :save_translations do
        # delete all previous translations of this record
        record_translations.destroy_all
        
        # loop through updated translations
        translations.each_pair do |locale, fields|
          fields.each_pair do |field, content|
            # create translation record
            record_translations.create :translatable_field => field, :locale => locale.to_s, :content => content unless content.blank?
          end
        end
      end
      
      define_method :get_field_content do |locale, field|
        # get I18n fallbacks
        if self.class.enable_locale_fallbacks && I18n.respond_to?(:fallbacks)
          locales = I18n.fallbacks[locale]
        else
          locales = [locale]
        end
        
        # content default
        content = nil
        
        # fallbacks
        locales.each do |l|
          if content = translations[l][field]
            break
          end
        end

        # return content
        content
      end

      define_method :set_field_content do |locale, field, content|
        # set field content
        translations[locale.to_sym][field] = content
      end
    end

    def enable_locale_fallbacks
      unless @enable_locale_fallbacks_set
        @enable_locale_fallbacks = true
        @enable_locale_fallbacks_set = true
      end
      @enable_locale_fallbacks
    end

    def enable_locale_fallbacks=(enabled)
      @enable_locale_fallbacks = enabled
      @enable_locale_fallbacks_set = true
    end
  end
end