source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# ruby '3.0.1'
ruby File.read('.ruby-version').strip
gem 'bcrypt'
gem 'bootstrap', '~> 5.3.0.alpha3'
gem 'chartkick', '~> 4.2'
gem 'country_select', '~> 8.0'
gem 'daemons'
gem 'deep_cloneable', '~> 3.2.0'
gem 'delayed_job_active_record'
gem 'groupdate', '~> 6.1'
gem 'honeybadger', '~> 5.2'
gem 'importmap-rails'
gem 'jbuilder', '~> 2.7'
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false
# for fater pagy performance https://ddnexus.github.io/pagy/docs/api/javascript/setup/
gem 'oj', '~> 3.16'
gem 'pagy'
gem 'pg', '~> 1.1'
gem 'phony_rails'
gem 'puma', '~> 5.0'
# gem 'rails', '~> 6.1.4', '>= 6.1.4.1'
gem 'rails', '~> 7.0.0'
gem 'rails-controller-testing'
gem 'rails-settings-cached', '~> 2.8'
gem 'razorpay'
# gem 'sass-rails', '>= 6'
gem 'sassc-rails'
gem 'stimulus-rails'
# gem 'turbolinks', '~> 5'
gem 'turbo-rails'
gem 'twilio-ruby'
# gem 'webpacker', '~> 5.0'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rails-erd'
  gem 'rubocop', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-rails', require: false
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  # DPS this gem causes an unwanted timer in top left of browser
  # https://stackoverflow.com/questions/65589200/how-to-remove-the-top-left-timer-counter-in-react-web-app
  # gem 'rack-mini-profiler', '~> 2.0'
  gem 'listen', '~> 3.3'
  gem 'spring'
  gem 'bullet'
end

group :test do
  gem 'capybara', '>= 3.26'
  gem 'faker'
  # DPS couldn't stub Whatsapp#send_whatsapp without this
  gem 'minitest-stub_any_instance', '~> 1.0'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Use Redis for Action Cable
gem 'redis', '~> 4.0'
