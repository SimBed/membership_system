class Shared::AchievementsController < Shared::BaseController
  before_action :set_achievement, only: [:show, :edit, :update, :destroy]

  def index
    @achievements = Achievement.order_by_date
  end

  def show; end

  def new
    @achievement = Achievement.new
    set_options
  end

  def edit
    set_options
  end

  def create
    @achievement = Achievement.new(achievement_params)
    if @achievement.save
      flash_message :success, t('.success')
      redirect_to shared_achievements_path
    else
      set_options
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @achievement.update(achievement_params)
      flash_message :success, t('.success')
      redirect_to shared_achievements_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @achievement.destroy
    flash_message :success, t('.success')
    redirect_to shared_achievements_path
  end

  private

  def set_achievement
    @achievement = Achievement.find(params[:id])
  end

  def set_options
    @challenges = Challenge.all
    @clients = Client.order_by_first_name
  end

  def achievement_params
    params.require(:achievement).permit(:date, :score, :challenge_id, :client_id)
  end
end
