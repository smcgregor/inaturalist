# Loads a bunch of dummy users, random users, taxa, and locations.  Run
# with script/runner

if ENV['RAILS_ENV'] == 'production' || RAILS_ENV == 'production'
  puts "Dude, you should NOT be running this in production"
  exit
end

%w"ted jenny kueda adam brad andy trey jessie arch n8".each do |login|
  puts "Creating the user '#{login}'..."
  user = User.new(
    :login => login,
    :email => "test_user+#{login}@example.com",
    :password => 'password',
    :password_confirmation => 'password',
    :time_zone => "Pacific Time (US & Canada)"
  )
  if user.valid?
    user.save

    #Auth workaround
    user = User.last
    user.register!
    user.activate!
    user.save
  else
    puts "Unable to create invalid user" 
  end
  puts "\tD'oh: #{user.errors.full_messages.join(', ')}" unless user.valid?
end
