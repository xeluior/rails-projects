require 'open3'

class EncodeUploadJob < ApplicationJob
  queue_as :default

  def perform(blob)
    @blob = blob
    Dir.mkdir(workdir) unless Dir.exist? workdir

    blob.open tmpdir: workdir do |file|
      @tmpfile = file.path

      # apply 2 pass h264 encoding and convert audio to aac
      run(first_pass) { |progress| puts progress }
      run(second_pass) { |progress| puts progress }
    end
  end

  private

  def run(command)
    progress = 0.0
    Open3.popen3(command) do |_, _, stderr|
      # iterate over CR delimited lines since FFMPEG overwrites output
      stderr.each "\r" do |line|
        if line =~ /time=(\d+):(\d+):(\d+.\d+)/
          current_time = ($1.to_i * 3600) + ($2.to_i * 60) + $3.to_f
          progress = current_time / duration
        end
        yield progress if block_given?
      end
    end
  end

  def ffmpeg = ENV['FFMPEG'] || 'ffmpeg'
  def name = File.basename(@blob.filename)
  def workdir = File.join(Dir.tmpdir, name)
  def pass_prefix = File.join(workdir, 'ffmpeg2pass')
  def duration = file_info['format']['duration'].to_f

  # ffmpeg options
  def input = %W[-i #{@tmpfile}]
  def generic_options = %w[-hide_banner -hwaccel auto]
  def video_options = %w[-c:v libx264 -preset veryslow -b:v 15M]
  def audio_options = %W[-codec:a #{audio_codec} -profile:a aac_low]
  def pass_log = %W[-passlogfile #{pass_prefix}]
  def pass1 = %w[-an -pass 1 -f null]
  def pass2 = %w[-pass 2]

  # ffmpeg commands
  def common = [ffmpeg, generic_options, input, video_options, pass_log].flatten!
  def first_pass = [common, pass1, '/dev/null'].flatten!
  def second_pass = [common, audio_options, pass2, output_filename].flatten!

  def audio_codec
    if audio_streams.first['codec_name'] == 'aac'
      'copy'
    else
      'libfdk_aac'
    end
  end

  def file_info
    @file_info ||= Open3.popen3('ffprobe', '-show_streams', '-show_format', '-print_format', 'json', @tmpfile) do |_, stdout, _|
      JSON.parse(stdout.read)
    end
  end

  def audio_streams
    @audio_streams ||= file_info['streams'].filter { |i| i['codec_type'] == 'audio' }
  end

  def output_filename
    outfilename = "#{basename}.mp4"
    File.join workdir, outfilename
  end
end
