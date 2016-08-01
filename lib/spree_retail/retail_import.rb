class RetailImport
  require 'retailcrm'

  def self.create_customers
    customers = RETAIL.customers.response
    customers['customers'].each do |customer|
      create_customer(customer)
    end
  end

  def self.create_customer(customer)
    if customer['email']
      user = Spree::User.where(email: customer['email']).first_or_create(password: SecureRandom.hex(10))
      address = user.bill_address || Spree::Address.new
      retail_address = customer['address'] ? [customer['address']['region'], customer['address']['city'], customer['address']['text']].compact.join(', ') : ''
      address.update(firstname: customer['firstName'] || 'no name', lastname: customer['lastName'] || 'no name', address1: retail_address || 'no address',
                     city: (customer['address'] && customer['address']['city']) || 'no city', country_id: (Spree::Country.first.id || 0),
                     zipcode: (customer['address'] && customer['address']['zipcode']) || 'no zipcode')
      address['phone'] = customer['phones'].first ? customer['phones'].first['number'] : 'no phone'
      address.save
      user.bill_address_id = address.id# if address.new_record?
      user.ship_address_id = address.id
      if ActiveRecord::Base.connection.column_exists?(:spree_users, :first_name)
        user.first_name = customer['firstName']
      end
      if ActiveRecord::Base.connection.column_exists?(:spree_users, :last_name)
        user.last_name = customer['lastName']
      end
      user.retail_id = customer['id']
      if user.save
        RETAIL.customers_fix_external_ids([{id: customer['id'], externalId: user.id}])
      end
      user
    else
      false
    end
  end

  def self.create_orders
    customers = RETAIL.orders.response
    customers['orders'].each do |order|
      create_order(order)
    end
  end

  def self.create_order(order)
    spree_order = Spree::Order.where(id: order['externalId']).first_or_initialize
    # order_exists = Spree::Order.find_by(number: order['number']) unless order_exists

    spree_order.assign_attributes(number: order['number'], item_total: order['summ'], total: order['totalSumm'], email: order['email'],
                    special_instructions: order['customerComment'].to_s + order['managerComment'].to_s, completed_at: order['createdAt'],
                    shipment_total: (order['delivery'] && order['delivery']['cost']), channel: 'RetailCRM', item_count: (order['items'] && order['items'].size))

    if order['customer'] && order['customer']['email']
      user = Spree::User.find_by(email: order['customer']['email']) || create_customer(order['customer'])
      spree_order.user = user
      spree_order.ship_address = user.ship_address
      spree_order.bill_address = user.bill_address
    end
    if Spree::User.admin.present?
      spree_order.created_by = Spree::User.admin.first
    end
    add_states_to_order(spree_order, order['status'], order['paymentStatus'])
    spree_order.retail_id = order['id']
    if spree_order.save
      RETAIL.orders_fix_external_ids([{id: order['id'], externalId: spree_order.id}])
    end

  end

  def self.add_states_to_order(spree_order, state, payment_state)
    if Spree::Config.state_connection['order']
      inverted_states = Spree::Config.state_connection['order'].invert
      spree_order.state = inverted_states[state] || spree_order.state || 'complete'
    end
    if Spree::Config.state_connection['payment']
      inverted_payment_states = Spree::Config.state_connection['payment'].invert
      spree_order.payment_state = inverted_payment_states[payment_state] || spree_order.payment_state || 'paid'
    end
    # if Spree::Config[:state_connection]['shipment']
    #   inverted_states = Spree::Config[:state_connection]['order'] = Spree::Config.state_connection['shipment'].invert
    #   spree_order.shipment_state = inverted_states[state]
    # end
  end

  def self.update_states(options)
    if options[:payment_method]
      Spree::Config[:payment_method] = options[:payment_method]
    elsif options[:delivery_method]
      Spree::Config[:delivery_method] = options[:delivery_method]
    else
      Spree::Config[:state_connection] = options
    end
  end

  def self.export_all_orders
    existing_orders = RETAIL.orders.response['orders'].map{|o| o['externalId']}
    Spree::Order.where.not(id: existing_orders).each do |order|
      order.spree_send_created
    end
  end

  def self.export_all_customers
    existing_customers = RETAIL.customers.response['customers'].map{|c| c['externalId']}
    Spree::User.where.not(id: existing_customers).each do |customer|
      customer.spree_send_created
    end
  end

  def self.check_order(id)
    begin
      RETAIL.orders_get(id).response['success']
    rescue
      false
    end
  end

  def self.check_user(id)
    begin
      RETAIL.customers_get(id).response['success']
    rescue
      false
    end
  end

end