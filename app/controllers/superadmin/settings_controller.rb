class Superadmin::SettingsController < Superadmin::BaseController

  def show
    @errors = []
    @amnesties = YAML.dump(Setting.amnesty_limit).gsub('!ruby/hash:ActiveSupport::HashWithIndifferentAccess','')
    @sunsets = YAML.dump(Setting.sunset_limit_days).gsub('!ruby/hash:ActiveSupport::HashWithIndifferentAccess','')
  end

  def create
    @errors = ActiveModel::Errors.new(self)
    setting_params.keys.each do |key|
      next if setting_params[key].nil?

      setting = Setting.new(var: key)
      setting.value = setting_params[key].strip
      unless setting.valid?
        @errors.merge!(setting.errors)
      end
    end

    if @errors.any?
      render :show
    end
    setting_params.keys.each do |key|
      Setting.send("#{key}=", setting_params[key].strip) unless setting_params[key].nil?
    end

    redirect_to superadmin_settings_path, notice: "Setting was successfully updated."
  end

  private
    def setting_params
      params.require(:setting).permit(:whitelist, :renew_online, :timetable, :goals, :levels, :studios, :classmaker_advance, :sunset_limit_days, :package_expiry_message_days, :trial_expiry_message_days, :quotation, :amnesty_limit,
                                      :pre_expiry_package_renewal, :post_expiry_trial_renewal, :pre_expiry_trial_renewal, :attendances_remain, :days_remain)
    end

end