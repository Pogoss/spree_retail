cache @etag do 
  xml.instruct!
  xml.yml_catalog(date: Time.now.strftime('%F %T')) do
    xml.shop do
      shop_name = (Spree::Store.first && Spree::Store.first.name).try(:truncate, 250)
      xml.name(shop_name)
      xml.company(shop_name)
      xml.categories do
        Spree::Taxon.root.descendants.each do |t|
          cat_attributes = { id: t.id }
          cat_attributes[:parentId] = t.parent_id if t.parent_id && !t.parent.root?
          xml.category t.name, cat_attributes
        end
      end
      xml.offers do
        @products.each do |p|
          if p.has_variants? && p.taxons.any?
            variants = p.variants.
              joins('inner join spree_option_values_variants clr_values_variants on clr_values_variants.variant_id=spree_variants.id').
              joins('inner join spree_option_values clr_values on clr_values_variants.option_value_id=clr_values.id').
              joins("inner join spree_option_types clr_type on clr_values.option_type_id=clr_type.id and clr_type.name='color'").
              joins('inner join spree_option_values_variants sz_values_variants on sz_values_variants.variant_id=spree_variants.id').
              joins('inner join spree_option_values sz_values on sz_values_variants.option_value_id=sz_values.id').
              joins("inner join spree_option_types sz_type on sz_values.option_type_id=sz_type.id and sz_type.name='size'").
              reorder("clr_values.presentation, sz_values.presentation desc")
            variants.each do |v|
              xml.offer(id: v.id, productId: p.id, quantity: v.total_on_hand) do
                xml.url color_product_url(p, color: v.options[:color][:slug])
                xml.price v.price
                xml.purchasePrice v.cost_price || v.price
                xml.categoryId p.taxons.first.id if p.taxons.any?
                xml.picture variant_image_url(v, :large, :protocol => :request)
                xml.name v.name
                xml.productName p.name
                xml.param(p.sku, name: Spree.t(:sku), code: 'article') if p.sku.present?
                xml.param(v.description, name: Spree.t(:description), code: 'description') unless v.description.blank?
                xml.param(v.weight, name: Spree.t(:weight), code: 'weight') if v.weight > 0
                v.options.each do |option, values|
                  xml.param(values[:name], name: values[:type], code: option.to_s)
                end
             end
            end
          end
        end
      end
    end
  end
end