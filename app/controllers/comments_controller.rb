class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @event = Event.find(params[:event_id])
    @comment = Comments::CreateService.call(current_user, @event, comment_params)

    if @comment.persisted?
      redirect_to event_path(@event), notice: "Comentario publicado exitosamente."
    else
      redirect_to event_path(@event), alert: @comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    authorize @comment
    @event = @comment.event

    @comment.destroy
    redirect_to event_path(@event), notice: "Comentario eliminado exitosamente."
  end

  private

  def comment_params
    params.require(:comment).permit(:content, :rating)
  end
end
