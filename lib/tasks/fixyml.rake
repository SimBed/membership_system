desc 'quick fix for yml file after column removed from db'
task yml_quickfix: :environment do
  open(Rails.root.join('test/fixtures/purchases.yml'), 'r') do |f|
    open(Rails.root.join('test/fixtures/purchases_dup.yml'), 'w') do |f2|
      f.each_line do |line|
        #NOTE: the blank spaces at the start of each line in yml
        f2.write(line) unless line.start_with?('  adjust_restart', '  ar_date', '  ar_payment', '  invoice')
      end
    end
  end
end
