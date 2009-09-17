#
# Place the CSV file in the directory with this script
# CSV file must be formatted according to the rules on
# /observations/new/batch_csv
#
require "csv"
FILE_NAME = "tools/lepidoptera2.csv"
@ratatosk = Ratatosk::Ratatosk.new()
@skip_list = []
@epic_fail_list = []
@graft_failures = []
    
def rat_find(name)
  
  if @skip_list.include?(name) and name.split(" ").length > 1
    name = name.split(" ")[0]
    puts "\tName was previously not found, moving to genus\n"
    taxon = Taxon.find(:first, 
      :include => :taxon_names, 
      :conditions => ["taxon_names.name = ?", name])
    return taxon
  end
  
  puts "\tFinding #{name} in COL...\n"
  puts "\tSleeping for 3 seconds to reduce load on COL\n"
  sleep 3
  begin
    taxon_name = @ratatosk.find(name).first
  rescue Timeout::Error
    puts "\tTimed out, trying again in 5 secs\n"
    sleep 6
    taxon_name = @ratatosk.find(name).first
  end
    
  if taxon_name and !taxon_name.nil?
    puts "\tFound in ratatosk, saving the taxon..."
    taxon_name.save
    taxon_name.reload
    puts "\tGrafting..."
    begin
      @ratatosk.graft(taxon_name.taxon)
      taxon = Taxon.find(:first, 
        :include => :taxon_names, 
        :conditions => ["taxon_names.name = ?", name])
    rescue RatatoskGraftError
      @graft_failures << taxon_name.taxon
    end
    return taxon
  elsif name.split(" ").length == 2
    puts "\tWARNING: could not find taxon name for #{name} with ratatosk, moving to genus only\n"
    @skip_list << name
    return rat_find(name.split(" ")[0])
  else
    return nil
  end
end
    
def batch_csv

  if true
    @observations = []
    @hasInvalid = false
    csv = File.new(FILE_NAME)
    max_rows = 30000
    row_num = 0
    
    begin
      CSV::Reader.parse(csv) do |row|
        if row[0] or row[1] or row[2] or row[3] or row[4] or row[5]
          obsHash = {:user => User.first,
          :species_guess => row[0],
          :observed_on_string => row[1],
          :description => row[2],
          :place_guess => row[3],
          :time_zone => User.first.time_zone}
          
          if(row[0] and !row[0].nil?)
            puts "Processing #{row}\n"
            taxon = Taxon.find(:first, 
              :include => :taxon_names, 
              :conditions => ["taxon_names.name = ?", row[0]])
            unless taxon and !taxon.nil?
              taxon = rat_find(row[0])
            end
            if taxon and !taxon.nil?
              puts "\tassociating observation with taxon\n"
              obsHash.update(:taxon => taxon)
            else
              @epic_fail_list << row[0]
              puts "\tTaxon Name: #{row[0]}, could not be found or grafted, leaving as unkown\n"
              obsHash.update(:taxon => nil)
            end
          end
          
          if(row[4] && row[5]) 
            obsHash.update(:latitude=>row[4], :longitude=>row[5], :location_is_exact=>true)
          elsif row[3]
            places = Ym4r::GmPlugin::Geocoding.get(row[3])
            unless places.empty?
              latitude = places.first.latitude
              longitude = places.first.longitude
              obsHash.update(:latitude=>latitude, :longitude=>longitude, :location_is_exact=>false)
            end
          end
          obs = Observation.create(obsHash)
          obs.tag_list = row[6]
         @hasInvalid ||= !obs.valid?
         row_num += 1
         if obs.valid?
           puts "\t Observation saved\n"
         else
           puts "WARNING! This observation is invalid and was not saved\n"
         end
        end
        if row_num >= max_rows
          puts "You have a beehive of observations!<br /> We can only take your first #{max_rows} observations in every CSV\n"
          break
        end
      end
    rescue CSV::IllegalFormatError
      puts "Your CSV returned an illegal format exception. If the problem persists after you remove any strange characters, please email us the file and we'll figure out the problem\n"
      Kernel.exit
    end
  end
end

batch_csv
puts "\n\nEpic Fail List:\n\n#{@epic_fail_list}"
puts "\n\nSkip List:\n\n#{@skip_list}"
puts "\n\Graft Failures:\n\n#{@graft_failures}"
