desc 'update purchase status at end of each day'
task purchase_status_update: :environment do
  Purchase.where.not(status: 'expired').each do |p|
    status_new = p.status_calc
    p.update(status: status_new) unless p.status == status_new
  end
end
