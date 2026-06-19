module Events
  class UpdateService
    include ImageHandling

    def self.call(event, params)
      new(event, params).call
    end

    def initialize(event, params)
      @event = event
      @params = params.to_h.deep_symbolize_keys
      @primary_image_param = @params.delete(:primary_image)
      @images_params = @params.delete(:images) || []
      @remove_image_ids = @params.delete(:remove_image_ids) || []
    end

    def call
      # Asignamos el parámetro temporal para validación del modelo en actualización
      @event.primary_image_param = @primary_image_param if @primary_image_param.present?

      Event.transaction do
        # 1. Eliminar imágenes marcadas
        if @remove_image_ids.any?
          @event.event_images.where(id: @remove_image_ids).destroy_all
        end

        # 2. Reemplazar imagen principal si se provee una nueva
        if @primary_image_param.present?
          @event.event_images.where(display_order: 0).destroy_all
          build_and_save_image(@event, @primary_image_param, 0)
        end

        # 3. Actualizar atributos principales del evento
        if @event.update(@params)
          # 4. Agregar nuevas imágenes secundarias al carrusel
          @images_params.each do |img_param|
            next if img_param.blank?

            # Calcular el siguiente orden disponible
            last_order = @event.event_images.maximum(:display_order) || 0
            build_and_save_image(@event, img_param, last_order + 1)
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

  end
end
