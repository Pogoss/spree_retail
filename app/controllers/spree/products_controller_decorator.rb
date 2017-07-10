Spree::ProductsController.class_eval do

  caches_action :icml_catalog, if: Proc.new { |c| c.calculate_products_etag }, cache_path: :cache_path.to_proc

  def calculate_products_etag( fresh = false )
    return false if performed?
    @variants = Spree::Variant.available.joins('inner join spree_option_values_variants clr_values_variants on clr_values_variants.variant_id=spree_variants.id').
      joins('inner join spree_option_values clr_values on clr_values_variants.option_value_id=clr_values.id').
      joins("inner join spree_option_types clr_type on clr_values.option_type_id=clr_type.id and clr_type.name='color'").
      joins('inner join spree_option_values_variants sz_values_variants on sz_values_variants.variant_id=spree_variants.id').
      joins('inner join spree_option_values sz_values on sz_values_variants.option_value_id=sz_values.id').
      joins("inner join spree_option_types sz_type on sz_values.option_type_id=sz_type.id and sz_type.name='size'").
      reorder("spree_variants.product_id, clr_values.presentation, sz_values.presentation desc")
    digest = Digest::MD5.new()
    digest << Spree::Store.first.updated_at.to_i.to_s if Spree::Store.any?
    @etag = cache_key_for_flow( @variants, meta: false, request: true, initial_digest: digest.hexdigest )
    fresh || stale?(etag: @etag)
  end

  def icml_catalog
    unless performed?
      calculate_products_etag(true) if @etag.nil?
      respond_to do |format|
        format.xml
      end
    end
  end

end
