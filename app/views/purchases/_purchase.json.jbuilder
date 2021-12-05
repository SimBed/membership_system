json.extract! purchase, :id, :client_id, :product_id, :payment, :dop, :payment_mode, :invoice, :note, :adjust_restart, :ar_payment, :ar_date, :created_at, :updated_at
json.url purchase_url(purchase, format: :json)
