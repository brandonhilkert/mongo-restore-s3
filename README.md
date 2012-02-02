Mongo Restore S3
================

We host our MongoDB instances with MongoHQ. As part of their service, you can configure backups at various intervals and store them in various locations. We chose to back ours up to S3 as well so we always have additional copies available in another location.

One thing that often comes up is debugging issues that are dependent on production data. Because of this, we have to restore the DB in some manner, which usually involves a number of steps to get to the final result. This script was created to help alleviate the headaches associated with getting production data into a development system, specifically when stored in S3.

mongo-restore-s3.rb is a Ruby script that will download Mongo DBs that are backed up to S3 and restore them to a dev system. The restore script assumes that the application being restored a Rails app.

Install
-------

    $ gem install aws-s3

    $ git clone git@github.com:brandonhilkert/mongo-restore-s3.git


Usage
-----

    $ ruby mongo-restore-s3.rb -k [S3_key] -s [S3_secret] -b Mongo.Backup -d awesome_app_production -m awesome_app_development -n awesome

Because databases are sometimes large, and downloading from S3 could potentially take awhile, the script will by default use a copy that has already been download. To forcefully overwrite this behavior and download a new copy every time the script is run use the [-f] flag, like:

    $ ruby mongo-restore-s3.rb -k [S3_key] -s [S3_secret] -b Mongo.Backup -d awesome_app_production -m awesome_app_development -f