class AddIndexesToFlickrPhotos < ActiveRecord::Migration
  def self.up
    add_index :flickr_photos, :flickr_native_photo_id
    add_index :flickr_photos_taxa, [:taxon_id, :flickr_photo_id]
    add_index :flickr_photos_observations, [:observation_id, :flickr_photo_id], 
      :name => 'flickr_photos_observations_oid_fpid'
  end

  def self.down
    remove_index :flickr_photos, :flickr_native_photo_id
    remove_index :flickr_photos_taxa, [:taxon_id, :flickr_photo_id]
    remove_index :flickr_photos_observations, :name => 'flickr_photos_observations_oid_fpid'
  end
end
