# Revs Digital Library

This is a Blacklight Application for the Revs Digital Library at Stanford University.

## Getting Started

1. Checkout the code:

				cd [ROOT FOLDER LOCATION OF WHERE YOU WANT THE CODE TO GO]
        git clone https://github.com/sul-dlss/revs.git
				cd revs

1. [Optional] If you want to use rvmrc to manage gemsets, copy the .rvmrc example files:

        cp .rvmrc.example .rvmrc
        cp deploy/.rvmrc.example deploy/.rvmrc

1. Install dependencies via bundler for both the main and deploy directories:

        bundle install
        cd deploy
        bundle install
        cd ..

1. Copy the .yml example files:

        cd revs
        rake revs:config
 
1. Migrate the database:

        rake db:migrate
        rake db:migrate RAILS_ENV=test

1. Load the test fixtures:

        rake jetty:start RAILS_ENV=test
        rake revs:index_fixtures RAILS_ENV=test
        rake jetty:stop RAILS_ENV=test

1. Start the development solr (you should first stop any other jetty processes if you have 
   multiple jetty-related projects):

        rake jetty:start

1. To index the records into an environment's core, ensure jetty is running, then:

        rake revs:index_fixtures

1. Start Rails:

        rails s
    
1. Go to <http://localhost:3000>

## Terms Dialog Box

Configuration for the terms dialog box is in the application_controller.rb.

The "show_terms_dialog?" method defines when and if the terms dialog needs to be shown (it should return true or false based on whatever
logic you want).

The "accept_terms" method defines what happens when the user accepts.  It can set a cookie with a specific expiration if you don't 
want the user to see the terms dialog box again for a specific period of time (which could be very long if you essentially want never again).

## Deployment

    cd deploy
    cap production deploy # for production
    cap staging deploy # for staging
    cap development deploy # for development

You must specify a branch or tag to deploy.  You can deploy the latest by specifying "master"

## Testing

You can run the test suite locally by running:

    rake local_ci
    
This will stop development jetty, force you into the test environment, start jetty, start solr, 
delete all the records in the test solr core, index all fixtures in `spec/fixtures`, run `db:migrate` in test,
then run the tests, and then restart development jetty
