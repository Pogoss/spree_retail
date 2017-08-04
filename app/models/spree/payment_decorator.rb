module Spree
  Payment.class_eval do
    after_create :send_spree_created
    before_update :send_spree_updated

    def spree_generate_payment
      p = 
      {
        amount: amount.to_f,
        paidAt: updated_at.strftime('%Y-%m-%d %T'),
        order: { externalId: order.id },
        externalId: id
      }
      p[:status] = Spree::Config[:state_connection]['payment'][state] if Spree::Config[:state_connection]['payment'].present? && Spree::Config[:state_connection]['payment'].key?(state)
      p[:type] = Spree::Config[:payment_method][payment_method.id.to_s] if Spree::Config[:payment_method].present? && Spree::Config[:payment_method].key?(payment_method.id.to_s)
      p
    end

    def spree_send_created
      RETAIL.payments_create(self.spree_generate_payment) if order.try(:complete?) && !order.spree_send_if_not_exists
    end

    def spree_send_updated
      RETAIL.payments_edit(self.spree_generate_payment) if order.try(:complete?) && !order.spree_send_if_not_exists
    end

  end
end
