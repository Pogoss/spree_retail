module Spree
  module RetailHelper

    def order_states_config(state_name)
      Spree::Config[:state_connection]['order'][state_name]
    end

  end
end
