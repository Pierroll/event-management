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
      if @params[:price_min].present?
        relation = relation.where("price >= ?", @params[:price_min])
      end
      if @params[:price_max].present?
        relation = relation.where("price <= ?", @params[:price_max])
      end
      relation
    end
  end
end
