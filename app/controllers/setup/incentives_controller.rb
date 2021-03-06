class Setup::IncentivesController < PrivateController
  helper_method :incentive
  attr_reader :incentive

  def new
    @incentive = IncentiveConfig.new
    incentive.state_id = current_project.packages.first.states.configurables(true).first.id
    incentive.package_id = current_project.packages.first.id
    incentive.start_date = Date.today.to_date.beginning_of_month.strftime("%Y-%m")
    incentive.end_date = Date.today.to_date.end_of_month.strftime("%Y-%m")
    @project = current_project
    incentive.project = @project
  end

  def create
    @incentive = IncentiveConfig.new(incentive_params)
    @project = current_project
    incentive.package = @project.packages.find(incentive.package_id) if incentive.package_id
    incentive.state = State.find(incentive.state_id) if incentive.state_id
    incentive.project = current_project
    if incentive.valid?
      if incentive.activity_incentives && params[:set_values]
        status = incentive.set_data_elements_values
        if status.success?
          ttl_affected = status.raw_status["import_count"]["imported"] + status.raw_status["import_count"]["updated"]
          flash[:success] = "#{incentive.state.name}-#{incentive.package.name} created successfuly for #{ttl_affected} Org. Units"
          redirect_to(root_path)
        else
          flash[:error] = "#{incentive.state.name}-#{incentive.package.name} problem setting values to all  #{ttl_affected} Org. Units"
          render "new"
        end
      else
        @incentive.find_or_create_activity_incentives
        render "new"
      end
    else
      render "new"
    end
  end

  def update; end

  def incentive_params
    params.require(:incentive_config)
          .permit(:state_id,
                  :package_id,
                  :start_date,
                  :end_date,
                  entity_groups:                  [],
                  activity_incentives_attributes: %i[value name external_reference])
  end
end
