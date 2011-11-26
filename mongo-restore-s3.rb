require 'optparse'
require 'aws/s3'

working_directory_path = Dir.pwd + "/"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: mongo-restore-s3.rb [options]"

  opts.on("-b", "--bucket BUCKET", "Amazon S3 Bucket name") do |bucket|
    options[:bucket] = bucket
  end  
  opts.on("-k", "--key KEY", "Amazon S3 Key") do |key|
    options[:s3_key] = key
  end  
  
  opts.on("-s", "--secret SECRET", "Amazon S3 Secret") do |secret|
    options[:s3_secret] = secret
  end
  
  opts.on("-p", "--path PATH", "Application path") do |path|
    options[:app_path] = path
  end  
  
  opts.on("-d", "--database NAME", "Name of extracted DB") do |db|
    options[:db] = db
  end  
  
  opts.on("-m", "--mongo NAME", "Name of Mongo DB to restore to") do |db|
    options[:mongo] = db
  end
end.parse!

# Check if extracted DB folder already exists
if File::directory? (working_directory_path + options[:db])

  puts "Found existing extracted DB"
  puts ""
  puts "    Note: If you wanted to restore from a new download,"
  puts "          delete the meeteor_production folder containing "
  puts "          the extracted DB."
  
else
  connection = AWS::S3::Base.establish_connection!(
    :access_key_id     => options[:s3_key], 
    :secret_access_key => options[:s3_secret]
  )

  if connection
    puts "Successfully connected to S3..."
  else
    exit
  end

  puts ""
  puts "Available S3 Buckets"
  puts "===================="
  puts AWS::S3::Service.buckets.map(&:name)

  puts ""
  puts "Selecting Mongo Backup Bucket..."
  mongo_backup_bucket = AWS::S3::Bucket.find(options[:bucket])

  puts "Found #{mongo_backup_bucket.objects.count} backups..."
  puts "Selecting latest backups..."

  latest_backup_object = mongo_backup_bucket.objects.last

  puts "Downloading backup..."
  aFile = File.new("mongo_backup.tgz", "w+")
  aFile.syswrite(latest_backup_object.value)

  puts ""
  puts "Extracting backup..."
  system "tar xzvf mongo_backup.tgz"

  puts ""
  puts "Removing system.indexes & system.users"
  Dir.chdir(working_directory_path + options[:db])
  File.delete("system.indexes.bson")
  File.delete("system.users.bson")
end

puts ""
puts "Dumping existing db with rake..."
Dir.chdir(options[:app_path])
system "rake db:drop"

puts ""
puts "Restoring backup..."
Dir.chdir(working_directory_path + options[:db])
system "mongorestore -d #{options[:mongo]} ."

puts "Done!"