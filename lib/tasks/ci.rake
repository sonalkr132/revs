require 'jettywrapper' unless Rails.env.production? 
require 'rest_client'

# before doing stuff with fixtures, be sure we are not running in production or pointing to a actual real solr server
def allowed_solr?
  !Rails.env.production? && Blacklight.solr.uri.port != 8080 && !Blacklight.solr.uri.to_s.include?('sul-solr') && !Blacklight.solr.uri.to_s.include?('stanford.edu')
end

namespace :jetty do
    
  desc "Restart jetty with new settings and reload fixtures"
  task :reset do
    Rake::Task["jetty:stop"].invoke
    Rake::Task["revs:config"].invoke
    sleep 3
    Rake::Task["jetty:start"].invoke
    sleep 1
    Rake::Task["revs:refresh_fixtures"].invoke
  end
end

desc "Run continuous integration suite"
task :ci do
  Rails.env='test'
  ENV['RAILS_ENV']='test'
  Jettywrapper.wrap(Jettywrapper.load_config) do
    Rake::Task["local_ci"].invoke
  end
end

desc "Assuming jetty is already running - then migrate, reload all fixtures and run rspec"
task :local_ci do  
  Rails.env='test'
  ENV['RAILS_ENV']='test'
  Rake::Task["revs:refresh_fixtures"].invoke
  Rake::Task["db:migrate"].invoke
  Rake::Task["db:fixtures:load"].invoke
  Rake::Task["db:seed"].invoke
  Rake::Task["revs:update_item_title"].invoke  
  Rake::Task["rspec"].invoke
end

namespace :revs do

  desc "Check development options"
  task :dev_options_set => :environment do
    if Revs::Application.config.simulate_sunet_user || !Revs::Application.config.use_editstore
      puts '**************************************************************'
      puts '****** WARNING: SOME DEVELOPMENT ONLY OPTIONS ARE SET ********'
      puts '**************************************************************'
    end
  end
  
  desc "Copy configuration files"
  task :config do
    cp("#{Rails.root}/config/database.yml.example", "#{Rails.root}/config/database.yml") unless File.exists?("#{Rails.root}/config/database.yml")
    cp("#{Rails.root}/config/solr.yml.example", "#{Rails.root}/config/solr.yml") unless File.exists?("#{Rails.root}/config/solr.yml")
    cp("#{Rails.root}/config/synonyms.txt", "#{Rails.root}/jetty/solr/dev/conf/synonyms.txt")
    cp("#{Rails.root}/config/synonyms.txt", "#{Rails.root}/jetty/solr/test/conf/synonyms.txt")
    cp("#{Rails.root}/config/schema.xml", "#{Rails.root}/jetty/solr/dev/conf/schema.xml")
    cp("#{Rails.root}/config/schema.xml", "#{Rails.root}/jetty/solr/test/conf/schema.xml")
    cp("#{Rails.root}/config/solrconfig.xml", "#{Rails.root}/jetty/solr/dev/conf/solrconfig.xml")
    cp("#{Rails.root}/config/solrconfig.xml", "#{Rails.root}/jetty/solr/test/conf/solrconfig.xml")
  end  
  
  desc "Delete and index all fixtures in solr"
  task :refresh_fixtures do
    if allowed_solr?
      Rake::Task["revs:delete_records_in_solr"].invoke
      Rake::Task["revs:index_fixtures"].invoke
    else
      puts "Refusing to refresh fixtures.  You know, for safety.  Check your solr config."
    end
  end
  
  desc "Index all fixutres into solr"
  task :index_fixtures do
    if allowed_solr?
      add_docs = []
      Dir.glob("#{Rails.root}/spec/fixtures/*.xml") do |file|
        add_docs << File.read(file)
      end
      puts "Adding #{add_docs.count} documents to #{Blacklight.solr.options[:url]}"
      RestClient.post "#{Blacklight.solr.options[:url]}/update?commit=true", "<update><add>#{add_docs.join(" ")}</add></update>", :content_type => "text/xml"
    else
      puts "Refusing to index fixtures.  You know, for safety.  Check your solr config."
    end
  end
  
  desc "Clean up saved items - remove any saved items which reference items/solr documents that do not exist"
  task :cleanup_saved_items => :environment do |t, args|
    SavedItem.all.each { |saved_item| saved_item.destroy if saved_item.solr_document.nil? }
  end

  desc "Delete all records in solr"
  task :delete_records_in_solr do
    if allowed_solr?
      puts "Deleting all solr documents from #{Blacklight.solr.options[:url]}"
      RestClient.post "#{Blacklight.solr.options[:url]}/update?commit=true", "<delete><query>*:*</query></delete>" , :content_type => "text/xml"
    else
      puts "Refusing to delete fixtures.  You know, for safety.  Check your solr config."
    end
  end
end