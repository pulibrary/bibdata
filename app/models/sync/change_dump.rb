class Sync::ChangeDump < Sync::Dump
  self.table_name = 'sync_change_dumps'
  serialize :delete_ids
end
