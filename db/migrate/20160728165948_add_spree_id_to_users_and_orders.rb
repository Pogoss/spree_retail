class AddSpreeIdToUsersAndOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :retail_stamp, :datetime
    add_column :spree_users, :retail_stamp, :datetime
    add_column :spree_payments, :retail_id, :integer
    add_column :spree_orders, :retail_digest, :string
  end
end
