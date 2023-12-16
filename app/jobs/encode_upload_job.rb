require 'open3'

class EncodeUploadJob < ApplicationJob
  queue_as :default

  def perform(blob)
    blob.open tmpdir: workdir do |file|
      fd = Encoder.new file.path

      # apply 2 pass h264 encoding and convert audio to aac
      fd.run(:first_pass) { |progress| puts progress }
      fd.run(:second_pass) { |progress| puts progress }
    end
  end
end
