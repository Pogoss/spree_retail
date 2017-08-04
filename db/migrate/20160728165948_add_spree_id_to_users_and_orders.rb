class AddSpreeIdToUsersAndOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :retail_digest, :string
    add_column :spree_users, :retail_digest, :string
  end
end
