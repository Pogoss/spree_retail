module Spree
  User.class_eval do

    after_commit :spree_send

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

      digest = Digest::MD5.hexdigest(user.to_json)
      user = nil if digest==self.retail_digest

      { user: user, digest: digest }
    end

    def spree_send_created( info = nil )
      info = info || self.spree_generate_customer
      if info[:user].present?
        op = RETAIL.customers_create(info[:user])
        update_columns(retail_digest: info[:digest]) if op.is_successfull? 
      end
    end

    def spree_send_updated( info = nil )
      info = info || self.spree_generate_customer
      if info[:user].present?
        op = RETAIL.customers_edit(info[:user])
        update_columns(retail_digest: info[:digest]) if op.is_successfull? 
      end
    end

    def spree_send
      info = self.spree_generate_customer
      if info[:user].present?
        RetailImport.check_user(id) ? spree_send_updated(info) : spree_send_created(info)
      end
    end

    def spree_send_if_not_exists
      info = self.spree_generate_customer
      if info[:user].present? && !RetailImport.check_user(id)
        spree_send_created(info) 
        return(true)
      end
      false
    end

  end
end
