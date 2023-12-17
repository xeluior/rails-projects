class EncodingProgressChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    stream_for ActiveStorage::Blob.find(params[:blob_id])
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
