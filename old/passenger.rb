# -*- coding: utf-8 -*-
gem 'passenger'
create_file 'Procfile', <<-PROCFILE
web: bundle exec passenger start -p $PORT --max-pool-size 3
PROCFILE
