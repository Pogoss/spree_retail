module Spree
  Spree::Order.class_eval do
    after_create {|ord| ord.spree_send_created if ord.state == 'complete' && !ord.retail_id.present? }
    before_update {|ord| ord.spree_send_created if ord.state == 'complete' && ord.state_changed? && !ord.retail_id.present? }
    after_update {|ord| ord.spree_send_updated if ord.state == 'complete' && !ord.retail_id.present? }

    def spree_generate_order
      if user && !RETAIL.customers_get(user.id).response['success']
        user.spree_send_created
      end
      order = {
          externalId: id,
          number: number,
          email: email,
          createdAt: created_at.strftime('%Y-%m-%d %T'),
          paymentStatus: payment_state,
          # discountPercent: 10,
          firstName: user && user.ship_address && user.ship_address.firstname,
          lastName: user && user.ship_address && user.ship_address.lastname,
          customer: {
              externalId: user && user.id
              # firstName: user && user.ship_address && user.ship_address.firstname,
              # lastName: user && user.ship_address && user.ship_address.lastname,
              # phones: [{ number: user && user.ship_address && user.ship_address.phone }],
          }
      }
      # if shipments.present? && shipments.first.shipping_methods.present?
      #   order[:delivery] = {
      #       code: shipments.first.shipping_methods.first.name.downcase,
      #       cost: shipments.first.cost,
      #       address: {text: ship_address.to_s }
      #   }
      # end
      if ActiveRecord::Base.connection.column_exists?(:spree_users, :first_name)
        order[:firstName] = user.first_name
        order[:lastName] = user.last_name
      end
      if Spree::Config[:state_connection]['order'].present? && state
        order[:status] = Spree::Config[:state_connection]['order'][state]
      end
      if Spree::Config[:state_connection]['payment'].present? && payment_state
        order[:paymentStatus] = Spree::Config[:state_connection]['payment'][payment_state]
      end
      if Spree::Config[:payment_method].present? && payments.present?
        payment_method_name = payments.last.payment_method && payments.last.payment_method.name
        order[:paymentType] = Spree::Config[:payment_method][payment_method_name]
      end
      if Spree::Config[:delivery_method].present? && shipments.present?
        shipment_method_name = shipments.last.shipping_method && shipments.last.shipping_method.name
        order[:delivery] = {
            code: Spree::Config[:delivery_method][shipment_method_name],
            cost: shipments.last.cost,
            address: {text: ship_address.to_s }
        }
      end
      order[:items] = []
      line_items.each do |ln|
        order[:items] << {productId: ln.id , initialPrice: ln.price, quantity: ln.quantity, productName: ln.name}
      end
      order
    end

    def spree_send_created
      unless RetailImport.check_order(id)
        ord = self.spree_generate_order
        RETAIL.orders_create(ord).response
      end
    end

    def spree_send_updated
      if RetailImport.check_order(id)
        ord = self.spree_generate_order
        RETAIL.orders_edit(ord).response
      end
    end

  end
end