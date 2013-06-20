class Api::V1::PhotosController < Api::V1::ApiController

  # predefined maximum uploaded file size, 10M
  MAX_FILE_SIZE = 10 * 1024 * 1024

  # mobile app requires to upload audio/graph files, the scenario is that,
  # user might use carema to capture picture of candidate's answer on
  # whiteboard, and then he/she uploads it to the backend.

  def upload_file
    #NOTE: Do we need to define a input parameters verification method?
    interview_id = params[:interview_id]
    tempio = params[:file]
    if interview_id.nil? or tempio.nil?
      #NOTE: We may need a fine-grained error code definition.
      render :json => {:error => 'Invalid parameters.'}, :status => 400
    end

    if tempio.size > MAX_FILE_SIZE
      render :json => {:message => 'File size cannot be larger than 10M.'}, :status => 400
      return
    end

    begin
      interview = Interview.find interview_id
      photo = interview.photos.build
      photo.savefile(tempio.original_filename, tempio)

      render :json => {:photo_id => photo.id}, :status => 200
    rescue ActiveRecord::RecordNotFound => e
      # NOTE: We may need a fine-grained error code definition.
      render :json => {:error => 'No such interview.'}, :status => 400
    rescue Exception => e
      # NOTE: We may need a fine-grained error code definition.
      render :json => {:error => 'Unknown error.'}, :status => 403
    end
  end

  def list_files
    interview_id = params[:interview_id]
    if interview_id.nil?
      render :json => {:error => 'Invalid parameters.'}, :status => 400
    end

    begin
      interview = Interview.find interview_id
      photo_ids = interview.photos.map(&:id)

      render :json => {:photos => photo_ids}, :status => 200
    rescue ActiveRecord::RecordNotFound => e
      render :json => {:error => 'No such interview.'}, :status => 400
    end
  end

  def get_file
    photo_id = params[:photo_id]
    if photo_id.nil?
      render :json => {:error => 'Invalid parameters.'}, :status => 400
    end

    begin
      photo = Photo.find photo_id
      path = File.join(download_folder, Time.now.to_s)
      fp = File.new(path, 'wb')
      photo.readfile(fp)
      fp.close

      download_file(path)
      # NOTE: We need an async job to delete the temporary file.
    rescue ActiveRecord::RecordNotFound => e
      render :json => {:error => 'No such file.'}, :status => 400
    end

  end

private
  def download_folder
    folder = Rails.root.join('public', 'download')
    Dir.mkdir(folder) unless File.exists?(folder)
    folder
  end

  def download_file(filepath)
    mimetype = MIME::Types.type_for(filepath)
    filename = File.basename(filepath)
    File.open(filepath) do |fp|
      send_data(fp.read, :filename => filename, :type => "#{mimetype[0]}", :disposition => "inline")
    end
    File.delete(filepath)
  end

end
