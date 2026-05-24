module Events
  class CreateService
    def self.call(organizer, params)
      new(organizer, params).call
    end

    def initialize(organizer, params)
      @organizer = organizer
      @params = params.to_h.deep_symbolize_keys
      @images_params = @params.delete(:images) || []
    end

    def call
      event = @organizer.organized_events.build(@params)

      Event.transaction do
        if event.save
          @images_params.each do |img_param|
            next if img_param.blank?

            event_image = event.event_images.build
            if file_attachment?(img_param)
              event_image.file.attach(img_param)
            else
              event_image.image = img_param.to_s
            end
            event_image.save!
          end
          event
        else
          event
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      event.errors.add(:base, "No se pudieron guardar las imágenes: #{e.message}")
      event
    end

    private

    def file_attachment?(param)
      param.respond_to?(:tempfile) ||
        param.is_a?(ActiveStorage::Attachment) ||
        param.is_a?(ActionDispatch::Http::UploadedFile)
    end
  end
end
