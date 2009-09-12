#
# Creates taxa and names for all the iconic taxa.  This is to get a blank db
# up to speed.
#
# Run this with script/runner!
#
ICON_PARENTS = ["Good Practice", "Bad Practice"]
RANK_LEVELS = [
  'root',
  'kingdom',
  'phylum',
  'subphylum',
  'superclass',
  'class',
  'sublcass',
  'superorder',
  'order',
  'suborder',
  'superfamily',
  'family',
  'subfamily',
  'supertribe',
  'tribe',
  'subtribe',
  'genus',
  'species',
  'subspecies',
  'variety'
]


def add(parent, child, rank_index)
  tax = Taxon.create(
    :name => child,
    :source => Source.find_by_title('San Diego Coastkeeper'),
    :rank => RANK_LEVELS[rank_index])
  tax.set_scientific_taxon_name
  tax.save
  if ICON_PARENTS.include?(parent)
    tax.is_iconic = true
    tax.save
  end
  tax.reload.move_to_child_of(Taxon.find_by_name(parent))
end

#parent is the name of the parent
#children is a hash
def load_tree(parent, children, rank_index)
  if children.is_a?(Array)
    children.each do |tax|
      add(parent, tax, rank_index) #base case
    end
  else
    children.each do |child_name, grandchildren|
      add(parent, child_name, rank_index)
      load_tree(child_name, grandchildren, rank_index+1) #recursive step 
    end
  end
end

require 'yaml'
starting_taxa = YAML.load(File.open("#{RAILS_ROOT}/tools/starting_taxa.yml"))
puts "Adding water"
water = Taxon.create(
  :name => "Water Practices", 
  :rank => 'root', 
  :source => Source.find_by_title('San Diego Coastkeeper'))
water.iconic_taxon = water
water.save
water.set_scientific_taxon_name
load_tree("Water Practices", starting_taxa, 1)