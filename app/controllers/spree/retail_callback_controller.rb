module Spree
  class RetailCallbackController < Spree::BaseController
    skip_before_action :verify_authenticity_token, only: [:retail_update_order, :retail_update_user]

    def retail_update_order
      sleep 1
      retail_order = RETAIL.orders_get(params[:order_id], 'id').response['order']
      RetailImport.create_or_update_order(retail_order)
      head :ok
    end

    def retail_update_user
      retail_customer = RETAIL.customers_get(params[:customer_id], 'id').response['customer']
      RetailImport.create_customer(retail_customer)
      head :ok
    end
  end
end