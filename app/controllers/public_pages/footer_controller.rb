class PublicPages::FooterController < ApplicationController
  before_action :set_admin_status  
  layout 'admin'

  def about; end
  def terms; end
  def charges; end
  def package_policy
    @default_policy = logged_in_as?('client') ? current_account.client.default_policy : 'group' 
  end
  def privacy_policy; end
  def payment_policy; end
  def contact; end
end
