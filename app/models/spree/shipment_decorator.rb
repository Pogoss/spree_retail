module Spree
  Shipment.class_eval do
    after_commit :send_spree_order, unless: :retail_update

    attr_accessor :retail_update

    def send_spree_order
Rails.logger.info '*** shipment changed'
      order.spree_send if order
    end
  end
end