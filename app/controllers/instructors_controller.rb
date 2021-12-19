class InstructorsController < ApplicationController
  before_action :set_instructor, only: %i[show edit update destroy]

  def index
    @instructors = Instructor.all
  end

  def show
  end

  def new
    @instructor = Instructor.new
  end

  def edit
  end

  def create
    @instructor = Instructor.new(instructor_params)

      if @instructor.save
        redirect_to instructors_path
        flash[:success] = "Instructor was successfully created"
      else
        render :new, status: :unprocessable_entity
      end
  end

  def update
      if @instructor.update(instructor_params)
        redirect_to instructors_path
        flash[:success] = "Instructor was successfully updated"
      else
        render :edit, status: :unprocessable_entity
      end
  end

  def destroy
    @instructor.destroy
      redirect_to instructors_url
      flash[:success] = "Instructor was successfully destroyed"
  end

  private
    def set_instructor
      @instructor = Instructor.find(params[:id])
    end

    def instructor_params
      params.require(:instructor).permit(:first_name, :last_name)
    end
end
