class JobFile < Sequel::Model(:job_input_file)
  def full_file_path
    File.absolute_path(file_path, dir_string = AppConfig[:job_file_path])
  end
end
