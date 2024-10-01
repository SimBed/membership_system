class Superadmin::BulkFreezesController < Superadmin::BaseController
  def show
    set_sessions
    handle_filter
    @recipient_list_size = @recipients.size
    @pagy, @recipients = pagy(@recipients, items: Rails.application.config_for(:constants)['recipient_pagination'])
    prepare_items_for_filters
  end

  def process_details
    session[:bulk_freeze_note] = params[:note]
    session[:bulk_freeze_start_date] = params[:start_date]
    session[:bulk_freeze_end_date] = params[:end_date]
    redirect_to bulk_freeze_path    
  end

  def filter
    clear_session(*session_filter_list)
    params_filter_list.each do |item|
      session["bulk_freeze_filter_#{item}".to_sym] = params[item]
    end
    redirect_to bulk_freeze_path
  end  

  def clear_filters
    clear_session(*session_filter_list)
    redirect_to bulk_freeze_path
  end

  def blast_off
    handle_filter
    max_recipient_blast_limit = Setting.max_recipient_blast_limit
    if @recipients.size > max_recipient_blast_limit
      flash[:warning] = t('.warning', max_recipient_blast_limit:)
      redirect_to bulk_freeze_path and return
    end
    start_date = session[:bulk_freeze_start_date].to_date
    end_date = session[:bulk_freeze_end_date].to_date
    note = session[:bulk_freeze_note]
    period = start_date..end_date
    passes = 0
    errors = 0
    @recipients.each do |recipient|
      freeze = recipient.freezes.create(start_date:, end_date:, note:, added_by: 'developer')
      recipient.update(expiry_date: recipient.expiry_date_calc)
      freeze.errors.present? ? errors += 1 : passes += 1
    rescue
      next
      errors += 1
    end
    flash[:success] = t('.success', errors: ActionController::Base.helpers.pluralize(errors, "membership"), passes: ActionController::Base.helpers.pluralize(passes, "membership"))
    redirect_to bulk_freeze_path
  end

  def remove_purchase
    session[:purchase_ids_remove] = purchase_ids_remove << params[:id]
    redirect_to bulk_freeze_path
  end  

  private

    def set_sessions
      @note = session[:bulk_freeze_note]
      @start_date = session[:bulk_freeze_start_date] || Time.zone.now.to_date
      @end_date = session[:bulk_freeze_end_date] || Time.zone.now.to_date
      @processed = true if @note
    end

    def handle_filter
      @recipients = Purchase.statuses(%w[ongoing])      
      %w[main_purchase].each do |key|
        @recipients = @recipients.send(key) if session["bulk_freeze_filter_#{key}"].present?
      end
      %w[workout_group].each do |key|
        @recipients = @recipients.send(key, session["bulk_freeze_filter_#{key}"]) if session["bulk_freeze_filter_#{key}"].present?
      end
      @recipients = @recipients.where.not(id: purchase_ids_remove)
      if session[:bulk_freeze_start_date] && session[:bulk_freeze_end_date]
        start_date = session[:bulk_freeze_start_date].to_date
        end_date = session[:bulk_freeze_end_date].to_date
        period = start_date..end_date
        #TODO: a membership already frozen for 1 day during a multi-day bulk freeze will not receive the freeze for the remaining days (and should)  
        @recipients = @recipients.reject {|recipient| recipient.freezes_cover?(period) || recipient.expires_before?(start_date)}
      end
      # HACK: convert back to ActiveRecord else pagy might fail
      @recipients = Purchase.where(id: @recipients.map(&:id)) if @recipients.is_a?(Array)
      @excluded_purchases = Purchase.where(id: purchase_ids_remove)
    end    

    def prepare_items_for_filters
      @workout_group = WorkoutGroup.distinct.pluck(:name).sort!
      # @statuses = %w[ongoing]
      @other_attributes = %w[main_purchase]
    end
    
    def params_filter_list
      %i[workout_group main_purchase]
    end
  
    def session_filter_list
      params_filter_list.map { |i| "bulk_freeze_filter_#{i}" } + %w[purchase_ids_remove]
    end

    def purchase_ids_remove
      session[:purchase_ids_remove] ||= []
    end    
end
