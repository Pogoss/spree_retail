module Spree
  Spree::Order.class_eval do
    after_create {|ord| ord.spree_send_created if ord.state == 'complete' && !ord.retail_stamp.present? }
    before_update {|ord| ord.spree_send_created if ord.state == 'complete' && ord.state_changed? && !ord.retail_stamp.present? }
    before_update {|ord| ord.spree_send_updated unless ord.retail_stamp_changed? }

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
      if adjustments.present?
        adjustments.each do |adj|
          order[:discount] = adj.amount * -1
        end
      end
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
      if Spree::Config[:state_connection]['shipment'].present? && shipment_state
        order[:status] = Spree::Config[:state_connection]['shipment'][shipment_state] && Spree::Config[:state_connection]['shipment'][shipment_state].first
      else
        order[:status] = 'new'
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
        shipping_cost = shipments.last.cost
        if shipments.last.adjustments.present?
          shipments.last.adjustments.each do |adj|
            shipping_cost = shipping_cost + adj.amount
          end
        end
        order[:delivery] = {
            code: Spree::Config[:delivery_method][shipment_method_name],
            cost: shipping_cost,
            address: {}
        }
        if ship_address
          order[:delivery][:address][:text] = "#{ship_address.city} #{ship_address.zipcode} #{ship_address.address1} #{ship_address.address2}"
        end
      end
      order[:items] = []
      line_items.each do |ln|
        order[:items] << {initialPrice: ln.price, quantity: ln.quantity, productName: ln.name, productId: ln.variant_id}
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
      if RetailImport.check_order(id)
        ord = self.spree_generate_order
        RETAIL.orders_edit(ord).response
      end
    end

  end
end