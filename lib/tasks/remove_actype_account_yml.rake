desc 'quick fix for yml file to remove actype'
task remove_actype: :environment do
  open(Rails.root.join('test/fixtures/accounts.yml'), 'r') do |f|
    # new line was being ignored when writing to yml so write (temporarily) to txt instead
    open(Rails.root.join('test/fixtures/accounts.dup.txt'), 'w') do |f2|
      f.each_line do |line|
        f2.write(line) unless line.start_with? '  ac_type:'
      end
    end
  end
end
