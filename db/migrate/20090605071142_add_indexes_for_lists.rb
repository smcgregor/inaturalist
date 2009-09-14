class AddIndexesForLists < ActiveRecord::Migration
  def self.up
    add_index :listed_taxa, [:list_id, :taxon_id]
    remove_index :observations, :taxon_id
    add_index :observations, [:taxon_id, :user_id]
    add_index :lists, :user_id
    add_index :list_rules, [:operand_type, :operand_id]
    add_index :list_rules, :list_id
  end

  def self.down
    remove_index :listed_taxa, [:list_id, :taxon_id]
    remove_index :observations, [:taxon_id, :user_id]
    add_index :observations, :taxon_id
    remove_index :lists, :user_id
    remove_index :list_rules, [:operand_type, :operand_id]
    remove_index :list_rules, :list_id
  end
end
