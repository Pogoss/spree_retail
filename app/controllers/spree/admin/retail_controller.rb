module Spree
  module Admin
    class RetailController < Spree::Admin::BaseController
      helper 'spree/admin/navigation'
      layout '/spree/layouts/admin'


      def index
        @retail_states = RETAIL.statuses.response['statuses'].map{|k, v| [v['name'], k]}
        @payment_states = RETAIL.payment_statuses.response['paymentStatuses'].map{|k, v| [v['name'], k]}
        @payment_types = RETAIL.payment_types.response['paymentTypes'].map{|k, v| [v['name'], k]}
        @delivery_types = RETAIL.delivery_types.response['deliveryTypes'].map{|k, v| [v['name'], v['code']]}
        @user = Spree::User.new
      end

      def import_customers
        RetailImport.create_customers
        flash[:notice] = 'Successfully imported'
        redirect_to :back
      end

      def import_orders
        RetailImport.create_orders
        flash[:notice] = 'Successfully imported'
        redirect_to :back
      end

      # def states_connection
      #   @retail_states = RETAIL.statuses.response['statuses'].map{|k, v| [v['name'], k]}
      #   @user = Spree::User.new
      # end

      def update_states
        RetailImport.update_states(params[:state])
        flash[:notice] = 'Successfully updated'
        redirect_to :back
      end

      # def retail_update_order
      #   head :ok
      # end
      #
      # def retail_update_user
      #   head :ok
      # end

      def export_all_orders
        RetailImport.export_all_orders
        flash[:notice] = 'Successfully exported'
        redirect_to :back
      end

      def export_all_customers
        RetailImport.export_all_customers
        flash[:notice] = 'Successfully exported'
        redirect_to :back
      end

    end
  end
end
