class VideosController < ApplicationController
  def show
    @project = Project.find params[:project_id]
    @video = @project.videos.find params[:id]
  end

  def destroy
    @project = Project.find params[:project_id]
    @video = @project.videos.find params[:id]
    @video.purge
    redirect_to @project
  end
end
