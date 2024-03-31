desc 'quick fix for yml file to add amnesty'
task yml_amnesty: :environment do
  open(Rails.root.join('test/fixtures/attendances.yml'), 'r') do |f|
    # new line was being ignored when writing to yml so write (temporarily) to txt instead
    open(Rails.root.join('test/fixtures/attendances_dup.txt'), 'w') do |f2|
      f.each_line do |line|
        f2.write(line)
        f2.puts("  amnesty: false\n") if line.start_with? '  amendment_count: 0'
      end
    end
  end
end
