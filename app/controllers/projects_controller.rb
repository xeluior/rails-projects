class ProjectsController < ApplicationController
  before_action only: %i[show edit update destroy] do
    @project = Project.find params[:id]
  end

  def index
    @projects = Project.all
  end

  def new
    @project = Project.new
  end

  def update
    if @project.update project_params
      redirect_to @project
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @project = Project.new project_params
    if @project.save
      redirect_to @project
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, status: :see_other
  end

  private

  def project_params
    params.require(:project).permit(:name, videos: [])
  end
end
