desc 'remove payment_mode from purchases yml'
task yml_payment_mode: :environment do
  open(Rails.root.join('test/fixtures/purchases.yml'), 'r') do |f|
    open(Rails.root.join('test/fixtures/purchases_dup.yml'), 'w') do |f2|
      f.each_line do |line|
        #NOTE: the blank spaces at the start of each line in yml
        f2.write(line) unless line.start_with?('  payment_mode')
      end
    end
  end
end
