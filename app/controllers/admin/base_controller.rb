class Admin::BaseController < ApplicationController
  layout 'admin'
  before_action :admin_account  
end
