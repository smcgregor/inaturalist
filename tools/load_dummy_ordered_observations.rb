# Loads a bunch of dummy observations along every 10th lat/lon line
# with increasing time from left to right and down to up
# with random users and taxa 
# Run with script/runner, this might be useful for GE and other spatial debugging

if ENV['RAILS_ENV'] == 'production' || RAILS_ENV == 'production'
  puts "Dude, you should NOT be running this in production"
  exit
end

def String.random_alphanumeric(size=16)
  s = ""
  size.times do
    num = Kernel.rand(93)+33
    s << num.chr 
  end
  s
end

QUIET = false
START_TIME = Time.parse('1940-01-01')
END_TIME = Time.parse('2009-01-01')

time = START_TIME
time_step = (END_TIME - START_TIME)/(1000)

lat = -90
lon = -180
while lat <= 90
  while lon <=180
    taxon = Taxon.first(:offset => rand(Taxon.count))
    time += time_step
    obs = Observation.new(
      :user => User.all[rand(User.count)], 
      :taxon => taxon, 
      :species_guess => taxon.name,
      :observed_on_string => time.to_date.to_s,
      # :time_observed_at => time,
      # Create observations in the Bay Area
      :description => String.random_alphanumeric(100),
      :latitude => lat,
      :longitude => lon)
    if obs.valid? and obs.user.state=="active" 
      obs.save
      puts "Created #{obs}" unless QUIET
      lon += 10
    else
      puts "Invalid!, Skipping observation for user: #{obs.user}, NOTE: WILL NOT TERMINATE IF ALL ARE INVALID"
    end
  end
  lat += 10
  lon = -180
end
