class FooterController < ApplicationController
  layout 'login'

  def about; end

  def terms; end

  def charges; end

  def package_policy
    @default_policy = logged_in_as?('client') ? current_account.client.default_policy : 'group' 
  end

  def privacy_policy; end

  def payment_policy; end
end
