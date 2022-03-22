  desc 'quick fix for yml file after column removed from db'
  task :yml_quickfix do

    open(Rails.root.join('test', 'fixtures', 'purchases.yml'), 'r') do |f|
      open(Rails.root.join('test', 'fixtures', 'purchases_dup.yml'), 'w') do |f2|
        f.each_line do |line|
           f2.write(line) unless line.start_with? "  expired:"
        end
      end
    end
    #FileUtils.mv 'file.txt.tmp', 'file.txt'
  end
