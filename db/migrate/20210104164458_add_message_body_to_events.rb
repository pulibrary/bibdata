class AddMessageBodyToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :message_body, :string
  end
end
