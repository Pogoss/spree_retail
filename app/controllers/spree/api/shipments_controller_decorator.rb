module Spree
  module Api
    ShipmentsController.class_eval do

      after_filter :spree_send, only: [:ship, :ready, :add, :remove]

      def spree_send
        @shipment.order.spree_send_updated if @shipment && @shipment.order
      end

    end
  end
end