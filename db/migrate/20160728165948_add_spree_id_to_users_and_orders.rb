class AddSpreeIdToUsersAndOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :retail_id, :integer
    add_column :spree_users, :retail_id, :integer
  end
end
