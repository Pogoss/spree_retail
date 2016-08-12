module Spree
  Spree::Order.class_eval do
    after_create {|ord| ord.spree_send_created if ord.state != 'cart' && !ord.retail_stamp.present? }
    before_update {|ord| ord.spree_send_created if ord.state != 'cart' && ord.state_changed? && !ord.retail_stamp.present? }
    before_update {|ord| ord.spree_send_updated if ord.state != 'cart' && !ord.retail_stamp_changed? }

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
          customerComment: comment,
          customer: {
              externalId: user && user.id
          }
      }
      order[:phone] = ship_address.phone if ship_address && ship_address.phone.present?
      if ship_address
        order[:firstName] = ship_address.firstname
        order[:lastName] = ship_address.lastname
      end
      if ActiveRecord::Base.connection.column_exists?(:spree_users, :first_name) && user && !order[:firstName].present?
        order[:firstName] = user.first_name
        order[:lastName] = user.last_name
      end
      if user && user.ship_address && !order[:firstName].present?
        order[:firstName] = user.ship_address.firstname
        order[:lastName] = user.ship_address.lastname
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
        order[:paymentStatus] = Spree::Config[:state_connection]['payment'][payments.last.state]
      end
      if Spree::Config[:delivery_method].present? && shipments.present?
        shipment_method_name = shipments.last.shipping_method && shipments.last.shipping_method.name
        order[:delivery] = {
            code: Spree::Config[:delivery_method][shipment_method_name],
            cost: shipments.last.cost,
            address: {}
        }
        if ship_address
          order[:delivery][:address][:text] = "#{ship_address.city} #{ship_address.zipcode} #{ship_address.address1} #{ship_address.address2}"
        end
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
        self.retail_stamp = Time.now
      end
    end

    def spree_send_updated
      # if RetailImport.check_order(id)
        ord = self.spree_generate_order
        RETAIL.orders_edit(ord).response
      # end
    end

  end
end