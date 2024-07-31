class AddConstraintEventIdDump < ActiveRecord::Migration[7.1]
  def up
    change_column_null :dumps, :event_id, false
  end

  def down
    change_column_null :dumps, :event_id, true
  end
end
