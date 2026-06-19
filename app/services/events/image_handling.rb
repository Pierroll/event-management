# frozen_string_literal: true

module Events
  # Shared image handling methods for CreateService and UpdateService.
  module ImageHandling
    private

    def build_and_save_image(event, param, order)
      event_image = event.event_images.build(display_order: order)
      if file_attachment?(param)
        event_image.file.attach(param)
      else
        event_image.image = param.to_s
      end
      event_image.save!
    end

    def file_attachment?(param)
      param.respond_to?(:tempfile) ||
        param.is_a?(ActiveStorage::Attachment) ||
        param.is_a?(ActionDispatch::Http::UploadedFile)
    end
  end
end
