class Superadmin::BlastsController < Superadmin::BaseController
  def new
    @recipients = Client.all
    handle_filter
    @clients_to_add = Client.exclude(@recipients).order_by_first_name
    @message = session[:message]
    @final_message = session[:final_message]
    @recipient_list_size = @recipients.size
    @pagy, @recipients = pagy(@recipients, items: Rails.application.config_for(:constants)['recipient_pagination'])
  end

  # if i name the method create_message it cannot be found!!??
  def add_message
    greeting = "Hi [client name]\n"
    session[:message] = params[:message]
    session[:greeting] = params[:greeting]
    session[:final_message] = params[:greeting] == '1' ? greeting + params[:message] : params[:message]
    redirect_to superadmin_blasts_new_path
  end

  def filter
    clear_session(:filter_blast_packagee, :filter_blast_group_packagee, :filter_blast_group_packagee_not_rider, :filter_blast_nobody)
    set_blast_session(:packagee, :group_packagee, :group_packagee_not_rider, :nobody)
    redirect_to superadmin_blasts_new_path
  end

  def clear_filters
    clear_session(:filter_blast_packagee, :filter_blast_group_packagee, :filter_blast_group_packagee_not_rider, :filter_blast_nobody, :client_ids_remove, :client_ids_add)
    redirect_to superadmin_blasts_new_path
  end

  def test_blast
    Blast.new(receiver: 'me', message: session[:final_message]).send_whatsapp
    Blast.new(receiver: 'boss', message: session[:final_message]).send_whatsapp
    redirect_to superadmin_blasts_new_path
  end

  def blast_off
    @recipients = Client.all
    handle_filter
    if @recipients.size > 2
      flash[:success] = 'too many'
      redirect_to superadmin_blasts_new_path and return
    end
    # recipients = Client.where(whatsapp:'+4479405734').limit(2)
    passes = 0
    errors = 0
    @recipients.each do |recipient|
      Blast.new(receiver: recipient, message: session[:final_message]).send_whatsapp
      passes += 1
    rescue
      next
      errros += 1
    end
    # flash[:success] = t('.success')
    flash[:success] = t('.success', errors: ActionController::Base.helpers.pluralize(errors, "error"), passes: ActionController::Base.helpers.pluralize(passes, "pass"))
    redirect_to superadmin_blasts_new_path
  end

  def remove_client
    session[:client_ids_remove] = client_ids_remove << params[:id]
    session[:client_ids_add].delete(params[:id])
    redirect_to superadmin_blasts_new_path
  end

  def add_client
    session[:client_ids_add] = client_ids_add << params[:client_id]
    session[:client_ids_remove].delete(params[:client_id])
    redirect_to superadmin_blasts_new_path
  end


  private

    def client_ids_remove
      session[:client_ids_remove] ||= []
    end

    def client_ids_add
      session[:client_ids_add] ||= []
    end

    def handle_filter
      %w[packagee group_packagee group_packagee_not_rider nobody].each do |key|
        @recipients = @recipients.send(key) if session["filter_blast_#{key}"].present?
      end
      @recipients = @recipients.where.not(id: client_ids_remove).order_by_first_name
      unless client_ids_add.empty?
        ids = (client_ids_add + @recipients.unscope(:order).pluck(:id)).uniq
        @recipients = Client.where(id: ids).order_by_first_name
      end
      @excluded_clients = Client.where(id: client_ids_remove)
      @added_clients = Client.where(id: client_ids_add)
      # @clients.pluck(:id).to_json.bytesize
      # session[:client_ids] = @clients.pluck(:id).first(75)
    end

    #TODO: make dry - see set_session in sessions_helper.rb
    def set_blast_session(*args)
      args.each do |session_key|
        session["filter_blast_#{session_key}"] = params[session_key] || session["filter_blast_#{session_key}"]
      end
    end    
end
