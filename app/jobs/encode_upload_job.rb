require 'open3'

class EncodeUploadJob < ApplicationJob
  queue_as :default

  def perform(blob_id)
    logger.debug "Performing Encoding job for #{blob_id}"
    blob = ActiveStorage::Blob.find(blob_id)
    blob.open do |file|
      fd = Encoder.new file.path

      # apply 2 pass h264 encoding and convert audio to aac
      logger.debug "Started first pass of #{file.path}"
      fd.run(:first_pass) do |progress|
        EncodingProgressChannel.broadcast_to(blob, progress)
      end
      fd.run(:second_pass) { |progress| puts progress }
    end
  end
end
