class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
    # create translations table if it doesn't exist
    unless table_exists?(:record_translations)
      create_table :record_translations do |t|
        t.integer :translatable_id, :required => true
        t.string :translatable_type, :required => true
        t.string :translatable_field, :required => true
        t.string :locale, :length => 5, :required => true
        t.text :content
      end
      
      # add index
      add_index :record_translations, [:translatable_id, :translatable_type, :translatable_field, :locale], :name => "record_translations_index", :unique => true
    end

    # loop through columns and insert into record translations table
    <%= translatable_class %>.all.each do |record|<% columns.each do |column| %>
      if content = record.attributes["<%= column %>"]
        RecordTranslation.create :translatable_id => record.id, :translatable_type => "<%= translatable_type %>", :translatable_field => "<%= column %>", :locale => "<%= locale %>", :content => content
      end
    <% end %>end

    # delete translated columns<% columns.each do |column| %>
    remove_column :<%= translatable_table %>, :<%= column %>
    <% end %>

    # insert acts_as_translatable_on in model
    model_file_path = "app/models/<%= model_name %>.rb"
    old_contents = File.open(model_file_path).read
    new_contents = old_contents.gsub("class <%= translatable_class %> < ActiveRecord::Base\n", "class <%= translatable_class %> < ActiveRecord::Base\n  acts_as_translatable_on <%= columns.map { |c| ":#{c}" }.join(", ") %>\n\n")
    File.open(model_file_path, 'w') { |f| f.write new_contents }
  end
  
  def self.down
    # remove acts_as_translatable_on from model
    model_file_path = "app/models/<%= model_name %>.rb"
    old_contents = File.open(model_file_path).read
    new_contents = old_contents.gsub("  acts_as_translatable_on <%= columns.map { |c| ":#{c}" }.join(", ") %>\n", "")
    File.open(model_file_path, 'w') { |f| f.write new_contents }

    # re-add deleted columns
    # TODO: make sure that re-added columns are the same type as the original, if possible<% columns.each do |column| %>
    add_column :<%= translatable_table %>, :<%= column %>, :text
    <% end %>
    
    # insert values back into original table
    <%= translatable_class %>.all.each do |record|<% columns.each do |column| %>
      # get content
      if translation_record = RecordTranslation.where(["translatable_id = ? AND translatable_type = ? AND translatable_field = ? AND locale = ?", record.id, "<%= translatable_type %>", "<%= column %>", "<%= locale %>"]).first
        content = translation_record.content
        # update original record
        record.update_attribute :<%= column %>, content
      end
    <% end %>end
    
    # drop translations table
    drop_table :record_translations
  end
end