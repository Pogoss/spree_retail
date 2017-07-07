module Spree
  User.class_eval do

    after_create {|usr| usr.spree_send_created unless usr.retail_stamp.present? }
    after_update {|usr| usr.spree_send_updated unless usr.retail_stamp.present? }

    def spree_generate_customer
      user = {
          externalId: id,
          email: email,
          createdAt: created_at.strftime('%Y-%m-%d %T')
      }
      user[:sex] = (self.gender == 1) ? 'female' : 'male' if self.gender != 0
      user[:firstName] = self.first_name if self.first_name.present?
      user[:lastName] = self.last_name if self.last_name.present?
      phne = self.phone || u.orders.complete.last.try(:bill_address).try(:phone)
      user[:phones] = [ { number: phne } ] if phne.present?
      addr = last_used_address || addresses.first
      user[:address] = { text: addr.to_s, index: addr.zipcode } if addr.present?
      user
    end

    def spree_send_created
      unless RetailImport.check_user(id)
        user = self.spree_generate_customer
        RETAIL.customers_create(user).response
      end
    end

    def spree_send_updated
      if RetailImport.check_user(id)
        user = self.spree_generate_customer
        RETAIL.customers_edit(user).response
      end
    end

    def spree_send
      user = self.spree_generate_customer
      (RetailImport.check_user(id) ? RETAIL.customers_create(user) : RETAIL.customers_create(user)).response
    end

  end
end
