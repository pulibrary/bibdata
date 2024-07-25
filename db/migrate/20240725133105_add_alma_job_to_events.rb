class AddAlmaJobToEvents < ActiveRecord::Migration[7.1]
  def up
    add_column :events, :alma_job_status, :string
  end
  def down
    remove_column :events, :alma_job_status, :string
  end
end
