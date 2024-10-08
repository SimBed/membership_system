module ApplicationHelper
  include Pagy::Frontend
  
  def decorate(model_name, decorator_class = nil)
    (decorator_class || "#{model_name.class}Decorator".constantize).new(model_name) 
  end 

  #NOTE: dry up - used in instructors and blasts (as well as clients where it got shifted to the decorator)
  def number(whatsapp, phone)
    return nil if whatsapp.blank? && phone.blank?

    return phone.phony_formatted(format: :international, spaces: '-') if phone.present?

    whatsapp.phony_formatted(format: :international, spaces: '-')
  end  

  def flash_message(type, text = nil, now = nil)
    return if type.nil?

    if now
      flash.now[type] ||= []
      flash.now[type] << (text.is_a?(Array) ? text : [text])
    else
      flash[type] ||= []
      flash[type] << (text.is_a?(Array) ? text : [text])
    end
  end

  def render_flash
    rendered = []
    flash.each do |message_type, message_array|
      # rendered << render(partial: 'partials/flash', locals: { message_type:, message_array: }) if message_array.present?
      rendered << render('partials/flash', { message_type:, message_array: }) if message_array.present?
    end
    raw(rendered.join('<br/>'))
  end

  def months_logged(advanced: 0)
    first_class_date = Wkclass.order_by_date.last.start_time - 1.month
    last_class_date = Wkclass.order_by_date.first.start_time + advanced.months
    @months = months_between(first_class_date, last_class_date)
  end

  def purchase_years
    first_purchase_year = Purchase.order_by_dop.last.dop.year
    last_purchase_year = Purchase.order_by_dop.first.dop.year
    (first_purchase_year..last_purchase_year).map { |year| Date.new(year, 1, 1) }
  end

  def nillify_when_blank(params, *params_items)
    params_items.each { |item| params[item] = nil if params[item] == '' }
  end

  def month_period(date)
    date = Date.parse(date) unless date.is_a? Date
    beginning_of_period = date.beginning_of_month
    end_of_period = date.end_of_month.end_of_day
    (beginning_of_period..end_of_period)
  end

  def rupees(amount)
    number_to_currency(amount, precision: 0, unit: 'Rs. ')
  end

  def active_link_for(path:)
    'active' if request.path == path
  end

  def form_test
    form_with(url: '/', method: 'get', class: 'form-class', data: { turbo_frame: 'expenses' }) do |form|
      form.select :revenue_month, options_for_select(['feb']), {}, { class: 'sort', onchange: 'this.form.requestSubmit()' }
    end
  end

  private

  def months_between(start_date, end_date)
    (start_date.beginning_of_month.to_date..end_date.to_date).select { |d| d.day == 1 }.map { |d| d.strftime('%b %Y') }.reverse
  end
end
