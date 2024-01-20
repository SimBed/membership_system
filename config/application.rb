require_relative "boot"

require "rails/all"
# DPS for exporting data
require 'csv'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AttendanceSystem
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # DPS https://github.com/collectiveidea/delayed_job/tree/v4.1.10
    config.active_job.queue_adapter = :delayed_job    

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # remove red border from form error fields (otherwise a pain to remove when hotwiring)
    # https://stackoverflow.com/questions/5267998/rails-3-field-with-errors-wrapper-changes-the-page-appearance-how-to-avoid-t
    config.action_view.field_error_proc = Proc.new { |html_tag, instance| 
      html_tag
    }
  end
end

