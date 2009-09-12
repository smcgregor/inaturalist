#
# Creates default sources.
#
# Run this with script/runner!
#

unless col = Source.find_by_title('San Diego Coastkeeper')
  puts "Creating source for San Diego CoastKeeper..."
  col = Source.new(
    :in_text => 'San Diego Coastkeeper',
    :citation => 'San Diego Coastkeeper. <http://www.sdcoastkeeper.org/>.',
    :url => 'http://sdcoastkeeper.org',
    :title => 'San Diego Coastkeeper'
  )
  col.save
end
