class SbMigration < ActiveRecord::Migration[5.0]
  def change
    create_table(:sbs) do |t|
      t.string :timestamp
      t.integer :code
      t.integer :distance
      t.integer :button
      t.string :task_type
      t.string :task_id
      t.float :skill_score
      t.float :assignment_score
      t.string :worker_id
      t.integer :work_duration
      t.string :task_status
    end
  end
end
