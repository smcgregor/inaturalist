class IndexCleanup < ActiveRecord::Migration
  def self.up
    # This is a duplication of index_listed_taxa_on_list_id_and_taxon_id
    remove_index :listed_taxa, :list_id
    add_index :listed_taxa, :taxon_id
    add_index :colors_taxa, [:taxon_id, :color_id]
  end

  def self.down
    add_index :listed_taxa, :list_id
    remove_index :listed_taxa, :taxon_id
    remove_index :colors_taxa, [:taxon_id, :color_id]
  end
end
