# Pulse-Cruncher
Quickly crunch specific data set
___

# Installation

## Prerequisites

### Softwares

* postgresql-9.5
* redis
* ruby-2.4.1

## Install Steps
On a shell, run
```
$ git clone https://github.com/Bivek/pulse-cruncher.git
```
___
# Configuration
All changes are to be made to files relative to `pulse-cruncher` folder.
```
$ cd pulse-cruncher
```

## Post-installation
### config/sidekiq.yml
Set proper number of workers to run concurrently. Ideally, set it to number of cpu cores.

```
sed -i.original "s\^:concurrency:.*\:concurrency: $(printf "%d" $((1 + $(cat /proc/cpuinfo | grep processor | cut -d ':' -f 2 | sort -nr | head -n1))))\g" config/sidekiq.yml
```

### db/config.yml
Configure app to connect with postgres db server. Replace `POSTGRES_USER_PASSWORD` with password for user `postgres` which was created during installation of postgresql server.

```
sed -i.original "s\^  password:.*\  password: POSTGRES_USER_PASSWORD\g" db/config.yml
```

### Install gems
```
bundle install
```

### Create database schema
```
bundle exec rake db:create
```

### Migrate database schema
```
bundle exec rake db:migrate
```

### Set executable permissions
```
chmod 740 bin/console
```

### Start Sidekiq
```
bundle exec sidekiq &
```

___
# Usage

## Start app console
```
bundle exec bin/console
```

## Clean db
*Not required for the first run.*
```
App.clean_db
```

### Load data into the app
Load `unit` output json data into the app.
```
App.feed_data
```
Enter absolute path to text file containing each unit's output as json-per-line at the prompt `"Enter file path: "`.

After a series of `"."(s)` following prompt marks completion of data input: 

`"Done. Now you can start crunching by firing command App.start_crunching"`.


### Start data processing
All data imported in previous step will be queued for processing by running
```
App.start_crunching
```
Following message will be displayed when all tasks are queued.

`"Enqueued <nnn> unique tasks. Ouput will be obtained in a file named sb_<DATE>_<TIME>.json"`

Upon completion, the mentioned file contains summaries in json-per-line format.

Regularly monitor sidekiq queue "ds" to know the status of data processing. Queue will be empty when all processing is completed. From app console, run
```
require 'sidekiq/api'
Sidekiq::Queue.all
queue = Sidekiq::Queue.new("ds")
queue.count
```

### Format output into a CSV
Obtain tabular data from json-per-line format.
```
App.format_data
```
Specify full path to filename given by data processing step when asked at the prompt 

`"Enter file path for formatting: "`

Output will be saved and its path will be mentioned with message

`"Output generated at <OUTPUT_FILE_PATH>"`


