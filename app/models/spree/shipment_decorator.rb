module Spree
  Shipment.class_eval do
    after_commit :send_spree_order, unless: :retail_update

    attr_accessor :retail_update

    def send_spree_order
Rails.logger.info '*** shipment changed'
Rails.logger.info self.changed.inspect
Rails.logger.info self.previous_changes.inspect
      order.spree_send if order
    end
  end
end