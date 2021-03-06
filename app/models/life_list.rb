#
# A LifeList is a List of all the taxa a person has observed.
#
class LifeList < List
  before_create :set_defaults
  after_create :add_taxa_from_observations
  
  #
  # Adds a taxon to this life list by creating a new blank obs of the taxon
  # and relying on the callbacks in observation.  In theory, this should never
  # bonk on an invalid listed taxon...
  #
  def add_taxon(taxon)
    taxon_id = taxon.is_a?(Taxon) ? taxon.id : taxon
    listed_taxon = listed_taxa.find_by_taxon_id(taxon_id)
    if listed_taxon
      return listed_taxon.clone
    else
      ListedTaxon.create(:list => self, :taxon_id => taxon_id)
    end
  end
  
  #
  # Update all the taxa in this list, or just a select few.  If taxa have no
  # longer been observed, they will be deleted.  If they have been more
  # recently observed, their last_observation will be updated.  If taxa were
  # selected that were not in the list, they will be added if they've been
  # observed.
  #
  def refresh(params = {})
    add_new_taxa = params.delete(:add_new_taxa)
    if taxa = params[:taxa]
      # Find existing listed_taxa of these taxa to update
      collection = ListedTaxon.find(:all,
        :conditions => ["list_id = ? AND taxon_id IN (?)", self, taxa])
      
      # Add new listed taxa for taxa not already on this list
      if add_new_taxa
        (collection.map(&:taxon_id) | taxa.map(&:id)).each do |taxon_id|
          collection << ListedTaxon.new(
            :list => self,
            :taxon_id => taxon_id
          )
        end
      end
    else
      collection = self.listed_taxa
    end

    collection.each do |listed_taxon|      
      # update it
      listed_taxon = listed_taxon.update_last_observation
      
      # re-apply list rules to the listed taxa
      listed_taxon.save
      unless listed_taxon.valid?
        logger.debug "[DEBUG] #{listed_taxon} wasn't valid in #{self}, so " + 
          "it's being destroyed: " + 
          listed_taxon.errors.full_messages.join(', ')
        listed_taxon.destroy
      end
    end
  end
  
  # Add all the taxa the list's owner has observed.  This will be slow...
  def add_taxa_from_observations
    self.user.observations.all(:select => 'taxon_id', 
      :group => 'taxon_id', 
      :conditions => 'taxon_id IS NOT NULL').each do |observation|
      self.add_taxon(observation.taxon_id)
    end
  end
  
  private
  def set_defaults
    self.title ||= "%s's Life List" % self.user.login
    self.description ||= "Every species %s has ever seen." % self.user.login
  end
end
