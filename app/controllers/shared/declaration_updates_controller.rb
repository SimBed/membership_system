class Shared::DeclarationUpdatesController < Shared::BaseController
  skip_before_action :admin_or_instructor_account, except: :show
  before_action :junioradmin_account, only: %i[ new create edit update ]
  before_action :admin_account, only: %i[ destroy ]
  before_action :set_declaration_update, only: %i[ show edit update destroy ]
  before_action :set_declaration, only: %i[ new edit ]

  def new
    @declaration_update = DeclarationUpdate.new
  end

  def edit; end

  def show; end

  def create
    @declaration_update = DeclarationUpdate.new(declaration_update_params)

    respond_to do |format|
      if @declaration_update.save
        format.html { redirect_to client_declaration_declaration_update_path(client_id: @declaration_update.declaration.client.id, id: @declaration_update.id) }
        format.turbo_stream
      else
        @declaration = Client.find(params[:client_id]).declaration
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @declaration_update.update(declaration_update_params)
        format.html { redirect_to client_declaration_declaration_update_path(client_id: @declaration_update.declaration.client.id, id: @declaration_update.id) }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @declaration_update.destroy

    respond_to do |format|
      format.html { redirect_to declarations_path, notice: "Declaration update was successfully destroyed." }
      format.turbo_stream
    end
  end

  private
    def set_declaration_update
      @declaration_update = DeclarationUpdate.find(params[:id])
    end

    def set_declaration
      @declaration = Client.find(params[:client_id]).declaration
    end

    def declaration_update_params
      params.require(:declaration_update).permit(:date, :note, :declaration_id)
    end
end
