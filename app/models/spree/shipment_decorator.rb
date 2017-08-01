module Spree
  Shipment.class_eval do
    after_save :send_spree_order_update, unless: :retail_update

    attr_accessor :retail_update

    def send_spree_order_update
      order.spree_send_updated if order
    end
  end
end