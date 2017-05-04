require File.expand_path('../sidekiq_workers/base', File.dirname(__FILE__))

module SidekiqWorkers
  class Ds < SidekiqWorkers::Base
    sidekiq_options :queue => :ds, :retry => 3, :backtrace =>true

    KEY_CODES = {'0' => 'MOUSE', '8' => 'BS','9' => 'TAB','13' =>  'ENTER','16' =>  'SHIFT','17' =>  'CTRL','18' =>  'ALT','19' =>  'PAUSE','20' =>  'CAPS','27' =>  'ESC','32' =>  'SPACE','33' =>  'PAGE_UP','34' =>  'PAGE_DOWN','35' =>  'END','36' =>  'HOME','37' =>  'ARROW','38' =>  'ARROW','39' =>  'ARROW','40' =>  'ARROW','45' =>  'INSERT','46' =>  'DELETE','48' =>  'NUM_ROW','49' =>  'NUM_ROW','50' =>  'NUM_ROW','51' =>  'NUM_ROW','52' =>  'NUM_ROW','53' =>  'NUM_ROW','54' =>  'NUM_ROW','55' =>  'NUM_ROW','56' =>  'NUM_ROW','57' =>  'NUM_ROW','65' =>  'ALPHA','66' =>  'ALPHA','67' =>  'ALPHA','68' =>  'ALPHA','69' =>  'ALPHA','70' =>  'ALPHA','71' =>  'ALPHA','72' =>  'ALPHA','73' =>  'ALPHA','74' =>  'ALPHA','75' =>  'ALPHA','76' =>  'ALPHA','77' =>  'ALPHA','78' =>  'ALPHA','79' =>  'ALPHA','80' =>  'ALPHA','81' =>  'ALPHA','82' =>  'ALPHA','83' =>  'ALPHA','84' =>  'ALPHA','85' =>  'ALPHA','86' =>  'ALPHA','87' =>  'ALPHA','88' =>  'ALPHA','89' =>  'ALPHA','90' =>  'ALPHA','91' =>  'WIN_LEFT','92' =>  'WIN_RIGHT','93' =>  'SEL','96' =>  'NUM_PAD','97' =>  'NUM_PAD','98' =>  'NUM_PAD','99' =>  'NUM_PAD','100' => 'NUM_PAD','101' => 'NUM_PAD','102' => 'NUM_PAD','103' => 'NUM_PAD','104' => 'NUM_PAD','105' => 'NUM_PAD','106' => 'NUM_PAD_SYMBOL_MUL','107' => 'NUM_PAD_SYMBOL_ADD','109' => 'NUM_PAD_SYMBOL_SUB','110' => 'NUM_PAD_SYMBOL_POINT','111' => 'NUM_PAD_SYMBOL_DIV','112' => 'FUNCTION','113' => 'FUNCTION','114' => 'FUNCTION','115' => 'FUNCTION','116' => 'FUNCTION','117' => 'FUNCTION','118' => 'FUNCTION','119' => 'FUNCTION','120' => 'FUNCTION','121' => 'FUNCTION','122' => 'FUNCTION','123' => 'FUNCTION','144' => 'NUM_LOCK','145' => 'SCROLL_LOCK','186' => 'SYMBOL_SEMI_COLON','187' => 'SYMBOL_EQL','188' => 'SYMBOL_COMMA','189' => 'SYMBOL_SUB','190' => 'SYMBOL_POINT','191' => 'SYMBOL_FORWARD_SLASH','192' => 'SYMBOL_GRAVE_ACCENT','219' => 'SYMBOL_SQUARE_BRACKET_OPEN','220' => 'SYMBOL_BACKWARD_SLASH','221' => 'SYMBOL_SQUARE_BRACKET_CLOSE','222' => 'SYMBOL_QUOTE_SINGLE'}
    ARROWS = [37, 38, 39 ,40]
    MOUSE = [0]
    DE = (48..105).to_a + [186, 188, 189, 190, 191, 192, 222]
    TAB = [9]
    CTR = [17]

    def perform(params)
      task_id = params['task_id']
      file_name = params['file_name']
      sbs = Sb.where(task_id: task_id).order('timestamp asc')
      data_entries = sbs.select{|s| DE.include?(s.code)}
      total_events_recorded = sbs.count
      task_id = task_id
      worker_id = sbs.first.worker_id
      recorded_total_duration = sbs.first.work_duration
      observed_total_duration_with_regards_to_first_event = sbs.last.timestamp - sbs.first.timestamp
      observed_totoal_duration_with_regards_to_first_data_entry_initiation = (sbs.last.timestamp - data_entries.first.timestamp) rescue observed_total_duration_with_regards_to_first_event
      no_of_key_press_wrt_de = data_entries.count
      no_of_mouse_click = sbs.select{|s| s.code == 0 }.count
      total_distance_moved = sbs.sum(:distance)
      no_of_backspace_pressed = sbs.select{|s| s.code == 8 }.count
      started_at = sbs.first.timestamp
      completed_at = sbs.last.timestamp
      no_of_arrow_movements = sbs.select{|s| ARROWS.include?(s.code)}.count
      elapsed_total_duration_between_two_fields = 0
      data_entry_total_duration = 0
      no_keyboard_and_mouse_switch = 0
      no_of_shortcuts_used = sbs.select{|s| CTR.include?(s.code)}.count
      zoom_total_duration = 0
      no_of_zoom_sessions = 0
      no_of_zoom_done = 0
      activity_pattern = {}
      tab_encountered = false
      field_start_timer = nil

      sbs.each_with_index do |s, index|
          # field switching calculation
          if !tab_encountered && s.code == 9
           tab_encountered = true
           field_start_timer = sbs[index - 1].timestamp
          elsif field_start_timer && DE.include?(s.code)
           elapsed_total_duration_between_two_fields += (s.timestamp - field_start_timer)
           field_start_timer = nil
           tab_encountered = false
          end
          # data entry duration calculation
          unless index == 0
            data_entry_total_duration += (s.timestamp - sbs[index - 1].timestamp)  if DE.include?(s.code) && DE.include?(sbs[index - 1].code)
          end
          # keyboard and mouse switch
          unless index == 0
             no_keyboard_and_mouse_switch += 1 if s.code == 0 && sbs[index - 1].code !=0
          end
          # activity pattern
          unless index == 0
            key = "#{KEY_CODES[s.code.to_s]}-#{KEY_CODES[sbs[index - 1].code.to_s]}"
            duration = s.timestamp - sbs[index - 1].timestamp
            if activity_pattern.has_key?(key)
              activity_pattern[key] = {count: (activity_pattern[key][:count] + 1), total_duration: (activity_pattern[key][:total_duration] + duration)}
            else
              activity_pattern[key] = {count: 1, total_duration: duration}
            end
          end
          # zoom calculation
          if CTR.include?(s.code)
            zoom_found = false
            break_index = nil
            ((index +1)...sbs.size).to_a.each do |l|
               if sbs[l].code == 187
                  zoom_found = true
                  no_of_zoom_done += 1
                elsif sbs[l].code == 0

                else
                  break_index = l
                  break
                end
            end
            if zoom_found
              no_of_zoom_sessions += 1
              zoom_total_duration += (sbs[break_index].timestamp - s.timestamp)
            end
          end
      end

      final_obj = {
        total_events_recorded: total_events_recorded,
        task_id: task_id,
        worker_id: worker_id,
        recorded_total_duration: recorded_total_duration,
        observed_total_duration_with_regards_to_first_event: observed_total_duration_with_regards_to_first_event,
        observed_totoal_duration_with_regards_to_first_data_entry_initiation: observed_totoal_duration_with_regards_to_first_data_entry_initiation,
        no_of_key_press_wrt_de: no_of_key_press_wrt_de,
        no_of_mouse_click: no_of_mouse_click,
        total_distance_moved: total_distance_moved,
        no_of_backspace_pressed: no_of_backspace_pressed,
        started_at: started_at,
        completed_at: completed_at,
        no_of_arrow_movements: no_of_arrow_movements,
        elapsed_total_duration_between_two_fields: elapsed_total_duration_between_two_fields,
        data_entry_total_duration: data_entry_total_duration,
        no_keyboard_and_mouse_switch: no_keyboard_and_mouse_switch,
        no_of_shortcuts_used: no_of_shortcuts_used,
        zoom_total_duration: zoom_total_duration,
        no_of_zoom_sessions: no_of_zoom_sessions,
        no_of_zoom_done: no_of_zoom_done,
        activity_pattern: activity_pattern
      }
      File.open(file_name, 'a') do |f|
        f.puts final_obj.to_json
      end
    end
  end
end
