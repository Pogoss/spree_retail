module Spree
  module Api
    LineItemsController.class_eval do
      after_filter :spree_send

      def spree_send
        order.spree_send_updated if order
      end

    end
  end
end
