class Superadmin::BaseController < ApplicationController
  layout 'admin'
  before_action :superadmin_account
end
