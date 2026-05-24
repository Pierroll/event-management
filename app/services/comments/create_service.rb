module Comments
  class CreateService
    def self.call(user, event, params)
      new(user, event, params).call
    end

    def initialize(user, event, params)
      @user = user
      @event = event
      @params = params.to_h.deep_symbolize_keys
    end

    def call
      comment = @event.comments.build(@params.merge(user: @user))

      unless @event.published?
        comment.errors.add(:base, "No se puede comentar en un evento que no esté publicado.")
        return comment
      end

      comment.save
      comment
    end
  end
end
