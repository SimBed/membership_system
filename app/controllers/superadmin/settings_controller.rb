class Superadmin::SettingsController < Superadmin::BaseController
  def show
    @errors = []
    @amnesties = YAML.dump(Setting.amnesty_limit).gsub('!ruby/hash:ActiveSupport::HashWithIndifferentAccess', '')
    @sunsets = YAML.dump(Setting.sunset_limit_days).gsub('!ruby/hash:ActiveSupport::HashWithIndifferentAccess', '')
  end

  def create
    @errors = ActiveModel::Errors.new(self)
    params[:setting].keys.each do |key|
      next if params[:setting][key].nil?

      setting = Setting.new(var: key)
      setting.value = params[:setting][key].strip
      unless setting.valid?
        @errors.merge!(setting.errors)
      end
    end

    if @errors.any?
      render :show
    end
    params[:setting].keys.each do |key|
      Setting.send("#{key}=", params[:setting][key].strip) unless params[:setting][key].nil?
    end
    flash[:success] = 'Setting was successfully updated.'
    redirect_to superadmin_settings_path
  end

  private

  # dont need strong parameters. Requets can only come from superadmin
  # attempt to tidy up strong parameters with *Setting.all.map { |s| s.var } failed because the Setting with the relevant var only exists after first being set
  # def setting_params
  # params.require(:setting).permit(:whitelist, :renew_online, :password_length, :timetable, :goals, :levels, :studios, :classmaker_advance, :sunset_limit_days, :package_expiry_message_days, :trial_expiry_message_days, :quotation, :amnesty_limit,
  #                                 :pre_expiry_package_renewal, :post_expiry_trial_renewal, :pre_expiry_trial_renewal, :attendances_remain, :days_remain)
  #   params.require(:setting).permit(*Setting.all.map { |s| s.var })
  # end
end
