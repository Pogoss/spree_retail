module Spree
  Spree::AppConfiguration.class_eval do
    preference :state_connection, :json, default: {}
    preference :payment_method, :json, default: {}
    preference :delivery_method, :json, default: {}
  end
end
