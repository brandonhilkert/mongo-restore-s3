require 'optparse'
require 'aws/s3'

working_directory_path = "/tmp/"

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
  
  opts.on("-d", "--database NAME", "Name of extracted DB") do |db|
    options[:db] = db
  end  
  
  opts.on("-m", "--mongo NAME", "Name of Mongo DB to restore to") do |db|
    options[:mongo] = db
  end
end.parse!

Dir.chdir(working_directory_path)

# Check if extracted DB folder already exists
if File::directory? (options[:db])

  puts "Found existing extracted DB"
  puts ""
  puts "    Note: If you wanted to restore from a new download,"
  puts "          delete the #{working_directory_path}meeteor_production"
  puts "          folder containing the extracted DB."
  
else
  connection = AWS::S3::Base.establish_connection!(
    :access_key_id     => options[:s3_key], 
    :secret_access_key => options[:s3_secret]
  )

  if connection
    puts "Successfully connected to S3..."
  else
    puts "Unable to connect to S3. Invalid key/secret."
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
  latest_backup_object = mongo_backup_bucket.objects.last

  puts "Downloading latest backup..."
  aFile = File.new("mongo_backup.tgz", "w+")
  aFile.syswrite(latest_backup_object.value)

  puts ""
  puts "Extracting backup..."
  system "tar xzvf mongo_backup.tgz"

  puts ""
  puts "Removing system.indexes"
  File.delete("#{options[:db]}/system.indexes.bson")
end

puts ""
puts "Restoring backup..."
system "mongorestore --drop -d #{options[:mongo]} #{options[:db]}"

puts "Done!"