require 'optparse'
require 'aws/s3'

working_directory_path = "/tmp/"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: mongo-restore-s3.rb [options]"

  opts.on("-b", "--bucket BUCKET", "Amazon S3 Bucket name") do |bucket|
    options[:bucket] = bucket
  end

  opts.on("-n", "--name NAME", "Object prefix") do |name|
    options[:object_prefix] = name
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
  
  options[:force] = false
  opts.on("-f", "--force", "Force overwriting of previously downloaded backup") do |f|
    options[:force] = true
  end
end.parse!

Dir.chdir(working_directory_path)

# Check if extracted DB folder already exists and
# the user doesn't want to overwrite
if File::directory?(options[:db]) && !options[:force]

  puts "Found existing extracted DB"
  puts ""
  puts "    Note: If you wanted to restore from a new download,"
  puts "          use the --force flag to overwrite the existing copy."
  
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
  puts "Selecting bucket...#{options[:bucket]}"
  mongo_backup_bucket = AWS::S3::Bucket.find(options[:bucket])

  latest_backup_object = options[:object_prefix] ? mongo_backup_bucket.objects(:prefix => options[:object_prefix]).last : mongo_backup_bucket.objects.last

  puts "Downloading latest backup...#{latest_backup_object.key}"
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