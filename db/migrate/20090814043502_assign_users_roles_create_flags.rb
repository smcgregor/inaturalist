class AssignUsersRolesCreateFlags < ActiveRecord::Migration
  def self.up
    
    create_table :flags, :force => true do |t|
      t.column :flag, :string, :default => ""
      t.column :comment, :string, :default => ""
      t.column :created_at, :datetime, :null => false
      t.column :flaggable_id, :integer, :default => 0, :null => false
      t.column :flaggable_type, :string, :limit => 15,
        :default => "", :null => false
      t.column :user_id, :integer, :default => 0, :null => false
    end

    add_index :flags, ["user_id"], :name => "fk_flags_user"
        
    roles = ["admin", "curator"]
    roles.each do |role|
      Role.create(:name=>role)
    end
    
    User.find(:all,:conditions=>"login='n8agrin' OR login='kueda' OR login='jess' OR login='smcgregor08'").each do |user|
      user.roles = Role.all
    end
  end

  def self.down
    
    remove_index :flags, ["user_id"]
    
    drop_table :flags
    
    User.all.each do |user| 
      user.roles.each do |role| 
        role.destroy
      end 
    end
  end
end
