module Spree
  User.class_eval do

    after_save :spree_send

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
      user = self.spree_generate_customer
      RETAIL.customers_create(user).response
    end

    def spree_send_updated
      user = self.spree_generate_customer
      RETAIL.customers_edit(user).response
    end

    def spree_send
      RetailImport.check_user(id) ? spree_send_updated : spree_send_created
    end

    def spree_send_if_not_exists
       spree_send_created unless RetailImport.check_user(id)
    end

  end
end
