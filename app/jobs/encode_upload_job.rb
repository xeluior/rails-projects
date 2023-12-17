require 'open3'

class EncodeUploadJob < ApplicationJob
  queue_as :default

  def perform(blob_id)
    blob = ActiveStorage::Blob.find(blob_id)
    blob.open do |file|
      fd = Encoder.new file.path

      # apply 2 pass h264 encoding and convert audio to aac
      broadcast_progress = proc do |progress|
        EncodingProgressChannel.broadcast_to(blob, progress)
      end
      fd.run(:first_pass, &broadcast_progress)
      fd.run(:second_pass, &broadcast_progress)

      # upload the new blob
      new_filename = "#{blob.filename.base}.mp4"
      new_blob = File.open fd.output_filename do |file|
        ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: new_filename,
          content_type: 'video/mp4',
          metadata: { encoded: true }
        )
      end

      # replace the old blob on all attachments
      blob.attachments.each do |attachment|
        attachment.blob = new_blob
      end
      blob.purge
    end
  end
end
