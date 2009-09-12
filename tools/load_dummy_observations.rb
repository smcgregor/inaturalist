# Loads a bunch of dummy observations, random users, taxa, and locations.  Run
# with script/runner

if ENV['RAILS_ENV'] == 'production' || RAILS_ENV == 'production'
  puts "Dude, you should NOT be running this in production"
  exit
end

QUIET = false
EARLIEST_TIME = Time.parse('2007-01-01')
LATEST_TIME = Time.now

500.times do
  taxon = Taxon.first(:offset => rand(Taxon.count))
  time = EARLIEST_TIME + rand(LATEST_TIME - EARLIEST_TIME)
  obs = Observation.new(
    :user => User.all[rand(User.count)], 
    :taxon => taxon, 
    :species_guess => taxon.name,
    :observed_on_string => time.to_date.to_s,
    # :time_observed_at => time,
    # Create observations in the Bay Area
    # :latitude => rand + 37, 
    # :longitude => (rand + 122)*-1)
    # Create obs in the northern part of the western hemisphere
    :latitude => rand * 80,
    :longitude => rand * -170)
  if obs.valid? and obs.user.state=="active" 
    obs.save
    puts "Created #{obs}" unless QUIET
  else
    puts "Invalid!, Skipping observation for user: #{obs.user}"
  end
end

# Observation.all.each {|o| o.destroy}
