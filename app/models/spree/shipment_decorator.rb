module Spree
  Spree::Shipment.class_eval do
    after_create :send_spree_order_update, unless: :retail_update
    before_update :send_spree_order_update#, unless: :retail_update

    attr_accessor :retail_update

    def send_spree_order_update
      if order
        File.open('public/retail.txt', 'a') { |file| file.write("#{changes.to_s} shipment\n") }
        order.spree_send_updated
      end
    end
  end
end