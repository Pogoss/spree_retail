module Spree
  Payment.class_eval do
    after_create :send_spree_created
    before_update :send_spree_updated
    before_destroy :send_spree_deleted

    def spree_generate_payment
      p = 
      {
        amount: amount.to_f,
        paidAt: created_at.strftime('%Y-%m-%d %T'),
        order: { externalId: order.id }
      }
      p[:status] = Spree::Config[:state_connection]['payment'][state] if Spree::Config[:state_connection]['payment'].present? && Spree::Config[:state_connection]['payment'].key?(state)
      p[:type] = Spree::Config[:payment_method][payment_method.id.to_s] if Spree::Config[:payment_method].present? && Spree::Config[:payment_method].key?(payment_method.id.to_s)
      if retail_id.present?
        p[:id] = retail_id 
      else
        p[:externalId] = id 
      end
      p
    end

    def send_spree_created
      if order.try(:complete?)
        op = RETAIL.payments_create(self.spree_generate_payment)
        if op.is_successfull?
          update_columns( retail_id: op.response['id'] )
        end
      end
    end

    def send_spree_updated
      RETAIL.payments_edit(self.spree_generate_payment) if order.try(:complete?) && retail_id.present?
    end

    def send_spree_deleted
      RETAIL.payments_delete(retail_id) if order.try(:complete?) && retail_id.present?
    end

  end
end
