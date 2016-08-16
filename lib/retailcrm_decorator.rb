Retailcrm.class_eval do

  def orders_get(id, by = 'externalId', site = nil)
    url = "#{@url}orders/#{id}"
    @params[:by] = by || 'externalId'
    @params[:site] = site
    make_request(url)
  end

  def orders_edit(order, by = 'externalId', site = nil)
    id = order[:externalId]
    url = "#{@url}orders/#{id}/edit"
    @params[:by] = by || 'externalId'
    @params[:order] = order.to_json
    @params[:site] = site
    make_request(url, 'post')
  end

  def customers_get(id, by = 'externalId', site = nil)
    url = "#{@url}customers/#{id}"
    @params[:site] = site
    @params[:by] = by || 'externalId'
    make_request(url)
  end

  def customers_edit(customer, by = 'externalId', site = nil)
    id = customer[:externalId]
    url = "#{@url}customers/#{id}/edit"
    @params[:by] = by || 'externalId'
    @params[:customer] = customer.to_json
    @params[:site] = site
    make_request(url, 'post')
  end

end