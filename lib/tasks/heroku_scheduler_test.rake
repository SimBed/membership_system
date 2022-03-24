desc 'test heroku scheduler'
task test_heroku_scheduler: :environment do
  Purchase.where(id: [73, 67]).each do |p|
    p.update(note: 'temp note')
  end
end
