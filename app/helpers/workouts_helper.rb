module WorkoutsHelper
  def image_exists?(workout_name)
    path = "group/#{workout_name.downcase}.jpg"
    return true if asset_exist?(path)

    false
  end
end
