Spree::ProductsController.class_eval do

  caches_action :icml_catalog, if: Proc.new { |c| c.calculate_products_etag }, cache_path: :cache_path.to_proc

  def calculate_products_etag( fresh = false )
    return false if performed?
    @products = Spree::Product.active
    digest = Digest::MD5.new()
    digest << Spree::Store.first.updated_at.to_i.to_s if Spree::Store.any?
    if @products.any?
      max_date = @products.respond_to?(:maximum) ? @products.maximum(:updated_at) : @products.max_by(&:updated_at).updated_at 
      digest << max_date.to_i.to_s
    end
    digest << request.format if !request.format.present?
    @etag = digest.hexdigest
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
