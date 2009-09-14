class AddRankLevelToTaxa < ActiveRecord::Migration
  def self.up
    add_column :taxa, :rank_level, :integer
    add_column :taxon_versions, :rank_level, :integer
    add_index :taxa, :rank_level
    
    puts "Normalizing weird rank names..."
    ['infraspecies', 'sub-class', 'variety', 'sub-species', 'var',
    'sub-family', 'sub-order', 'super-order', 'subsp', 'infraorder', 'form',
    'unranked', 'sub-division', 'super-family', 'sp', 'ssp', 'division',
    'tribe', 'gen'].each do |bad_rank|
      puts "\t#{bad_rank}..."
      Taxon.update_all(["rank = ?", Taxon.normalize_rank(bad_rank)], "rank = '#{bad_rank}'")
    end
    
    puts "Updating rank levels..."
    Taxon::RANKS.each do |rank|
      puts "\t#{rank}..."
      Taxon.update_all(["rank_level = ?", Taxon::RANK_LEVELS[rank]], "rank = '#{rank}'")
    end
  end

  def self.down
    remove_column :taxa, :rank_level
    remove_column :taxon_versions, :rank_level, :integer
  end
end
