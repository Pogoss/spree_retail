Spree::Order.class_eval do

  after_commit :spree_send

  def spree_generate_order
Rails.logger.info "*** spree_generate_order"
Rails.logger.info previous_changes.inspect
Rails.logger.info caller.join("\n")
    user.spree_send_if_not_exists
    order = 
    {
      externalId: id,
      number: number,
      email: email,
      createdAt: created_at.strftime('%Y-%m-%d %T'),
      phone: bill_address.try(:phone) || user.phone,
      firstName: bill_address.try(:first_name) || user.first_name,
      lastName: bill_address.try(:last_name) || user.last_name,
      customerComment: comment,
      customer: { externalId: user.id },
      call: need_call==1,
#      shipped: shipped?,
      status: 'new',
      discountManualAmount: (line_item_adjustments.nonzero.eligible.sum(:amount) + adjustments.nonzero.eligible.sum(:amount)).to_f * -1
    }

    if Spree::Config[:delivery_method].present? && shipments.present?
      code = Spree::Config[:delivery_method][shipments.first.shipping_method.id.to_s]
      if code.present? 
        order[:delivery] = 
        {
          code: code,
          cost: (shipment_total-shipping_discount).to_f,
          address: {}
        }
        if bill_address
          order[:delivery][:address][:text] = bill_address.addr
          order[:delivery][:address][:index] = bill_address.zipcode
        end
        if shipment_date.present?
          order[:delivery][:date] = shipment_date.strftime('%Y-%m-%d') 
          order[:delivery][:time] = 
          {
            from: shipment_range.lo_time,
            to: shipment_range.hi_time
          } if shipment_range.present?
        end
      end
    end

    order[:status] = Spree::Config[:state_connection]['order'][sstatus] if Spree::Config[:state_connection]['order'].present? && Spree::Config[:state_connection]['order'].key?(sstatus)

    if payments.present?
        order[:payments] = []
        payments.each do |payment|
          p = 
          {
             externalId: payment.id,
             amount: payment.amount.to_f,
             paidAt: payment.updated_at.strftime('%Y-%m-%d %T') 
          }
          p[:status] = Spree::Config[:state_connection]['payment'][payment.state] if Spree::Config[:state_connection]['payment'].present? && Spree::Config[:state_connection]['payment'].key?(payment.state)
          p[:type] = Spree::Config[:payment_method][payment.payment_method.id.to_s] if Spree::Config[:payment_method].present? && Spree::Config[:payment_method].key?(payment.payment_method.id.to_s)
          order[:payments] << p
        end
    end

    order[:items] = []
    line_items.each do |ln|
      order[:items] << 
      { 
        initialPrice: ln.price.to_f, 
        purchasePrice: (ln.cost_price || ln.price).to_f,
        quantity: ln.quantity, 
        productName: ln.name, 
        offer: { externalId: ln.variant_id } 
      }
    end
    order
  end

  def spree_send_created
    if complete?
      op = RETAIL.orders_create(self.spree_generate_order)
      if op.is_successfull? && payments.present?
        op = RETAIL.orders_get( id )
        op.response["order"]["payments"].each do |key,value|
          payment = payments.find_by(id: value["externalId"])
          if payment.present?
            payment.update_columns( retail_id: key )
          else
            RETAIL.payments_delete( key )
          end
        end if op.is_successfull?
      end
    end
  end

  def spree_send_updated
    if complete?
      ord = self.spree_generate_order
      RETAIL.orders_edit(ord).response
    end
  end

  def spree_send
    if complete?
      RetailImport.check_order(id) ? spree_send_updated : spree_send_created 
    end
  end
end