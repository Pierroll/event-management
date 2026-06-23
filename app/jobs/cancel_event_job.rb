# frozen_string_literal: true

class CancelEventJob < ApplicationJob
  queue_as :default

  def perform(event)
    results = Events::CancelService.call(event)
    Rails.logger.info "[CancelEventJob] Canceled event ##{event.id} (#{event.name}). " \
                      "Refunded: #{results[:refunded_count]}, Pending Canceled: #{results[:canceled_pending_count]}, " \
                      "Failures: #{results[:failed_bookings].size}"
  end
end
