module Analytics
  class CachedAnalyticsService
    def initialize(org_units, org_units_by_package, values, aggregation_per_data_elements)
      @values = values
      @org_units = org_units
      @org_units_by_package = org_units_by_package
      @values_by_data_element_and_period = @values.group_by { |value| [value["data_element"], value["period"]] }
      @aggregation_per_data_elements = aggregation_per_data_elements
    end

    def entities; end

    def activity_and_values(package, date)
      year_month = Periods.year_month(date)
      org_unit_ids = @org_units_by_package[package].map(&:id)
      values = package.activities.map do |activity|
        facts = facts_for_period(
          activity,
          package.current_values_periods(year_month),
          org_unit_ids
        )

        activity.activity_states.select(&:kind_formula?).each do |activity_state|
          facts[activity_state.state.code] = activity_state.formula
        end

        package.states.each do |state|
          facts[state.code] ||= 0
        end

        current_cycle_variables = build_cycle_variables(package, activity, year_month, org_unit_ids)
        previous_year_variables = package.use_previous_year_values? ? build_previous_year_variables(package, activity, year_month, org_unit_ids) : {}
        variables = current_cycle_variables.merge(previous_year_variables)
        #puts "#{year_month} #{activity.name} #{variables}"
        [activity, Values.new(date, facts, variables)]
      end
      values
    end

    def facts_for_period(activity, periods, org_unit_ids)
      activity.activity_states.select(&:external_reference?).map do |activity_state|
        activity_values = []
        periods.map do |formatted_period|
          activity_values += @values_by_data_element_and_period[[activity_state.external_reference, formatted_period.to_dhis2]] || []
        end
        activity_values = activity_values.select { |v| org_unit_ids.include?(v.org_unit) }
        [activity_state.state.code, aggregation(activity_values, activity_state)]
      end.to_h
    end

    def build_previous_year_variables(package, activity, year_month, org_unit_ids)
      variables = {}

      previous_facts = package.previous_year_periods(year_month).map do |period|
        [period, facts_for_period(activity, [period], org_unit_ids)]
      end.to_h

      activity.activity_states.map do |activity_state|
        vals = previous_facts.values.compact.map { |fact| fact[activity_state.state.code] }.compact
        vals = [0] if vals.empty?
        variables["#{activity_state.state.code}_previous_year_values"] = vals
      end

      activity.activity_states.each do |activity_state|
        variables["#{activity_state.state.code}_previous_year_values"] ||= [0]
      end

      package.states.each do |state|
        variables["#{state.code}_previous_year_values"] ||= [0]
      end

      variables
    end

    def build_cycle_variables(package, activity, year_month, org_unit_ids)
      previous_facts = package.current_cycle_periods(year_month).map do |period|
        facts_for_period(activity, [period], org_unit_ids)
      end

      activities_states = activity.activity_states.select(&:external_reference?)
      activities_states.map do |activity_state|
        [
          "#{activity_state.state.code}_current_cycle_values",
          previous_facts.map { |fact| fact[activity_state.state.code] || 0 }
        ]
      end.to_h
    end

    def aggregation(activity_values, activity_state)
      aggregation_type = @aggregation_per_data_elements[activity_state.external_reference] || "SUM"
      values_for_activity = activity_values.map { |v| v["value"] }.map(&:to_f)

      case aggregation_type
      when "MIN"
        values_for_activity.min
      when "MAX"
        values_for_activity.max
      when "SUM"
        values_for_activity.sum
      when "AVERAGE"
        values_for_activity.empty? ? 0 : values_for_activity.sum / values_for_activity.size
      else
        raise "aggregation_type #{aggregation_type} not supported"
      end
    end
  end
end
