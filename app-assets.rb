gsub_file 'app/assets/stylesheets/application.css', 'require_tree .', 'require_directory ./app'
create_file 'app/assets/stylesheets/app/.keep'
gsub_file 'app/assets/javascripts/application.js', 'require_tree .', 'require_directory ./app'
create_file 'app/assets/javascripts/app/.keep'
