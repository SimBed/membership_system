ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/mock'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  # fixtures :instructors, :workouts, :accounts, :clients, :partners, :wkclasses

  def is_logged_in?
    !session[:account_id].nil?
  end
  # def log_in_as(account)
  #   session[:account_id] = account.id
  # end

  # class ActionDispatch::IntegrationTest
  # Log in as a particular user.
  def log_in_as(account, password: 'password', remember_me: '1')
    return if account.nil?

    # Use the Ruby 3.1 hash literal value syntax when your hash key and value are the same.
    post login_path, params: { session: { email: account.email,
                                          password:,
                                          remember_me: } }
  end

  def log_out
    delete '/logout'
  end

  def switch_role_to(role)
    # get '/switch_account_role', params: { role: role }
    get switch_account_role_path(role:)
  end

  def month_period(date)
    date = Date.parse(date) unless date.is_a? Date
    beginning_of_period = date.beginning_of_month
    end_of_period = date.end_of_month.end_of_day
    (beginning_of_period..end_of_period)
  end

  def booking_count(booking_type)
    booked_count = 0
    (css_select 'div.status').each { |div| booked_count += 1 if div.text == booking_type }
    booked_count
  end
end
