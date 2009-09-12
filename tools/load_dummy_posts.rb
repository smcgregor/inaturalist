# Loads a bunch of dummy posts, random users, observations.  Run
# with script/runner

if ENV['RAILS_ENV'] == 'production' || RAILS_ENV == 'production'
  puts "Dude, you should NOT be running this in production"
  exit
end

QUIET = false
EARLIEST_TIME = Time.parse('2005-01-01')
LATEST_TIME = Time.now

500.times do
  user = User.all[rand(User.count)]
  time = EARLIEST_TIME + rand(LATEST_TIME - EARLIEST_TIME)
  lorem = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.  \nLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
  post = Post.new(
    :user => user,
    :parent => user,
    :published_at => time,
    :title => lorem[rand(lorem.size), 50],
    :body => lorem
  )

  if post.user.state == "active"
    post.save
    puts "Created #{post}" unless QUIET
  else
    puts "Unable to create post because it is invalid or it has an inactive user"
    puts post.user
  end
end
