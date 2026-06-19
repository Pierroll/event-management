module Events
  class SearchQuery
    def self.call(scope = Event.all, params = {})
      new(scope, params).call
    end

    def initialize(scope = Event.all, params = {})
      @scope = scope
      @params = params.to_h.deep_symbolize_keys
    end

    def call
      results = @scope

      results = filter_by_city(results)
      results = filter_by_category(results)
      results = filter_by_query(results)
      results = filter_by_dates(results)
      results = filter_by_price(results)

      results
    end

    private

    def filter_by_city(relation)
      if @params[:city].present?
        relation.by_city(@params[:city])
      else
        relation
      end
    end

    def filter_by_category(relation)
      if @params[:category_id].present?
        relation.by_category(@params[:category_id])
      else
        relation
      end
    end

    def filter_by_query(relation)
      if @params[:query].present?
        q = "%#{@params[:query].to_s.downcase}%"
        relation.where(
          "LOWER(name) LIKE :q OR LOWER(description) LIKE :q",
          q: q
        )
      else
        relation
      end
    end

    def filter_by_dates(relation)
      if @params[:start_date].present?
        relation = relation.where("start_date >= ?", @params[:start_date])
      end
      if @params[:end_date].present?
        relation = relation.where("start_date <= ?", @params[:end_date])
      end
      relation
    end

    def filter_by_price(relation)
      return relation if @params[:price_min].blank? && @params[:price_max].blank?

      conds = ["ticket_types.event_id = events.id"]
      binds = {}

      conds << "ticket_types.price >= :price_min" if @params[:price_min].present?
      binds[:price_min] = @params[:price_min] if @params[:price_min].present?

      conds << "ticket_types.price <= :price_max" if @params[:price_max].present?
      binds[:price_max] = @params[:price_max] if @params[:price_max].present?

      relation.where(
        "EXISTS (SELECT 1 FROM ticket_types WHERE #{conds.join(' AND ')})",
        binds
      )
    end
  end
end
