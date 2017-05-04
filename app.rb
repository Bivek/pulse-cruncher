require_relative 'boot'
require 'json'
require 'csv'

class App
  def self.feed_data
    puts "Enter file path: "
    file_path = gets.chomp
    unless File.file?(file_path)
      puts 'File not found'
      return
    end
    puts "Importing file: #{file_path}"
    data = File.read(file_path).split("\n")
    data.each do |daat|
      print '.'
      datum = JSON.parse(daat)
      task_info = {
        'assignment_score' => datum['assignment_score'],
        'skill_score' => datum['skill_score'],
        'task_id' => datum['task_id'],
        'task_status' => datum['task_status'],
        'task_type' => datum['task_type'],
        'work_duration' => datum['work_duration'],
        'worker_id' => datum['worker_id']
      }
      dat = datum['data']
      ActiveRecord::Base.transaction do
        create_record(task_info, dat['keyCodes']) unless dat['keyCodes'].nil?
        create_record(task_info, dat['mousemove']) unless dat['mousemove'].nil?
        create_record(task_info, dat['scroll']) unless dat['scroll'].nil?
        create_record(task_info, dat['mouseclick'], 1) unless dat['mouseclick'].nil?
      end
    end
  end

  def self.start_crunching
    file_name = "sb_#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}.json"
    task_ids = Sb.select('distinct task_id').pluck(:task_id)
    task_ids.each do |task_id|
      print '.'
      SidekiqWorkers::Ds.perform_async(task_id: task_id, file_name: file_name)
    end
    if task_ids.present?
      puts "Enqueued #{task_ids.count} unique tasks. Ouput will be obtained in a file named #{File.absolute_path(file_name)}"
    else
      puts "Your db is empty right now. First import require data and then proceed."
    end
  end

  def self.clean_db
    Sb.delete_all
  end


  def self.format_data
    output_file_name = "sb_#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_formatted.csv"
    puts "Enter file path for formatting: "
    file_path = gets.chomp
    unless File.file?(file_path)
      puts 'File not found'
      return
    end
    rows = File.read(file_path).split("\n")
    keys = ["total_events_recorded", "task_id", "worker_id", "recorded_total_duration", "observed_total_duration_with_regards_to_first_event", "observed_totoal_duration_with_regards_to_first_data_entry_initiation", "no_of_key_press_wrt_de", "no_of_mouse_click", "total_distance_moved", "no_of_backspace_pressed", "started_at", "completed_at", "no_of_arrow_movements", "elapsed_total_duration_between_two_fields", "data_entry_total_duration", "no_keyboard_and_mouse_switch", "no_of_shortcuts_used", "zoom_total_duration", "no_of_zoom_sessions", "no_of_zoom_done"]
    pattern_keys = []
    rows.each do |r|
      row = JSON.parse(r)
      pattern_keys << row['activity_pattern'].keys
    end

    pt = pattern_keys.flatten!.uniq.compact
    pat = []
    pt.each do |p|
      pat << "#{p}\#count"
      pat << "#{p}\#duration"
    end
    CSV.open(output_file_name, "wb") do |csv|
     csv << keys + pat
     rows.each do |r|
        out = []
        row = JSON.parse(r)
        keys.each do |key|
          out << row[key]
        end
        pt.each do |p|
          out << row['activity_pattern'][p]['count'] rescue 'NA'
          out << row['activity_pattern'][p]['total_duration'] rescue 'NA'
        end
        csv << out
     end
    end

    puts "Output generated at #{File.absolute_path(output_file_name)}"
  end

  private

  def self.create_record(task_info, data, button=nil)
    data.each do |datum|
      Sb.create!(
        assignment_score: task_info['assignment_score'],
        button: button || datum['button'],
        code: datum['code'],
        distance: datum['distance'],
        skill_score: task_info['skill_score'],
        task_id: task_info['task_id'],
        task_status: task_info['task_status'],
        task_type: task_info['task_type'],
        timestamp: datum['timestamp'],
        work_duration: task_info['work_duration'],
       worker_id: task_info['worker_id']
      )
    end
  end
end

