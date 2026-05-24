module Events
  class UpdateService
    def self.call(event, params)
      new(event, params).call
    end

    def initialize(event, params)
      @event = event
      @params = params.to_h.deep_symbolize_keys
      @images_params = @params.delete(:images) || []
      @remove_image_ids = @params.delete(:remove_image_ids) || []
    end

    def call
      Event.transaction do
        # 1. Eliminar imágenes marcadas
        if @remove_image_ids.any?
          @event.event_images.where(id: @remove_image_ids).destroy_all
        end

        # 2. Actualizar atributos principales del evento
        if @event.update(@params)
          # 3. Agregar nuevas imágenes
          @images_params.each do |img_param|
            next if img_param.blank?

            event_image = @event.event_images.build
            if file_attachment?(img_param)
              event_image.file.attach(img_param)
            else
              event_image.image = img_param.to_s
            end
            event_image.save!
          end
          @event
        else
          @event
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      @event.errors.add(:base, "No se pudieron procesar las imágenes: #{e.message}")
      @event
    end

    private

    def file_attachment?(param)
      param.respond_to?(:tempfile) ||
        param.is_a?(ActiveStorage::Attachment) ||
        param.is_a?(ActionDispatch::Http::UploadedFile)
    end
  end
end
