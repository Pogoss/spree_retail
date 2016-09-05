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
    order[:phone] = bill_address.phone if bill_address && bill_address.phone.present?
    if ship_address
      order[:firstName] = bill_address.firstname
      order[:lastName] = bill_address.lastname
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
      if bill_address
        retail_clean_order_address
        order[:delivery][:address][:text] = "#{bill_address.city} #{bill_address.zipcode} #{bill_address.address1} #{bill_address.address2}"
      end
    end
    order[:items] = []
    line_items.each do |ln|
      order[:items] << {initialPrice: ln.price, quantity: ln.quantity, productName: ln.name, productId: ln.variant_id}
    end
    order
  end

  def retail_clean_order_address
    if id
      clean_order = {externalId: id, customer: {externalId: user && user.id}, delivery: {address: {index: '', region: '', city: '', street: '', building: '', text: ''}}}
      RETAIL.orders_edit(clean_order)
    end
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