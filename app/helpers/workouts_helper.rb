module WorkoutsHelper
  def image_exists?(workout_name)
    path = "group/#{workout_name.downcase}.jpg"
    return true if asset_exist?(path)

    false
  end

  private
  # this code is repeated in booking_presenter.rb (dry out when come to implement a workout_presenter)
    def asset_exist?(path)
    if Rails.configuration.assets.compile
      Rails.application.precompiled_assets.include? path
    else
      Rails.application.assets_manifest.assets[path].present?
    end
  end  
end
