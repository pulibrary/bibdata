module Index
  class RemainingDumpsJob
    include Sidekiq::Worker

    def perform(index_manager_id)
      index_manager = IndexManager.find(index_manager_id)
      return unless index_manager.next_dump

      batch.jobs do
        index_manager.index_next_dump!
      end
    end
  end
end
