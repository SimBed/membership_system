ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  # fixtures :instructors, :workouts, :accounts, :clients, :partners, :wkclasses

  # def log_in_as(account)
  #   session[:account_id] = account.id
  # end

  # class ActionDispatch::IntegrationTest
  # Log in as a particular user.
  def log_in_as(account, password: 'password', remember_me: '1')
    return if account.nil?

    post login_path, params: { session: { email: account.email,
                                          password: password,
                                          remember_me: remember_me } }
  end

  def month_period(date)
    date = Date.parse(date) unless date.is_a? Date
    beginning_of_period = date.beginning_of_month
    end_of_period = date.end_of_month.end_of_day
    (beginning_of_period..end_of_period)
  end  
end
