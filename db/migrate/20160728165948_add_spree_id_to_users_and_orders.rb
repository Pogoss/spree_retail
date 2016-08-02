class AddSpreeIdToUsersAndOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :retail_stamp, :datetime
    add_column :spree_users, :retail_stamp, :datetime
  end
end
