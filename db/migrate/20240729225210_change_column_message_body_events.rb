class ChangeColumnMessageBodyEvents < ActiveRecord::Migration[7.1]
  def up
    add_index :events, :message_body, unique: true
  end

  def down
    remove_index :events, :message_body
  end
end
