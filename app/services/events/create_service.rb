module Events
  class CreateService
    include ImageHandling

    def self.call(organizer, params)
      new(organizer, params).call
    end

    def initialize(organizer, params)
      @organizer = organizer
      @params = params.to_h.deep_symbolize_keys
      @primary_image_param = @params.delete(:primary_image)
      @images_params = @params.delete(:images) || []
    end

    def call
      event = @organizer.organized_events.build(@params)
      
      # Asignamos el parámetro temporal para pasar la validación del modelo
      event.primary_image_param = @primary_image_param || @images_params.first

      Event.transaction do
        if event.save
          # Resolvamos cuál es la imagen principal y las secundarias
          primary = @primary_image_param
          secondaries = @images_params

          # Si no hay primary_image explícita pero hay imágenes en la lista,
          # tomamos la primera de la lista como la principal para mantener compatibilidad.
          if primary.blank? && secondaries.any?
            primary = secondaries.first
            secondaries = secondaries[1..-1] || []
          end

          # 1. Guardar la imagen principal (display_order: 0)
          if primary.present?
            build_and_save_image(event, primary, 0)
          end

          # 2. Guardar las imágenes secundarias (display_order >= 1)
          secondaries.each_with_index do |img_param, index|
            next if img_param.blank?
            build_and_save_image(event, img_param, index + 1)
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

  end
end
