module Spree
  Spree::Payment.class_eval do
    after_create :send_spree_order_update
    after_update :send_spree_order_update

    def send_spree_order_update
      if order
        order.spree_send_updated
      end
    end
  end
end
