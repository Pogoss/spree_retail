module Spree
  module Api
    ShipmentsController.class_eval do

      def ship
        unless @shipment.shipped?
          @shipment.ship!
        end
        @shipment.order.spree_send_updated if @shipment && @shipment.order
        respond_with(@shipment, default_template: :show)
      end

    end
  end
end