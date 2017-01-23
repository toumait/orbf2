class Setup::AutocompleteController < PrivateController
  def organisation_unit_group
    if params.key?(:term)
      organisation_unit_group_by_term_on_sol
    elsif params.key?(:siblings)
      organisation_unit_group_by_used_or_sibling_id
    else
      render_sol_items([])
    end
  end

  def data_elements
    dhis2 = current_project.dhis2_connection
    dataelements = dhis2.data_elements
                        .list(fields: "id,displayName", page_size: 20_000)
    render_sol_items(dataelements)
  end
end

private

def organisation_unit_group_by_term_on_sol
  pyr = Pyramid.new(current_project.dhis2_connection)

  org_unit_groups = pyr.org_unit_groups.map do |oug|
    ou_total = pyr.org_units_in_group(oug.id).size
    sample_ous = pyr.org_units_in_group(oug.id).to_a.shuffle.slice(0, 5).map(&:display_name)
    {
      type:  "option",
      value: oug.id,
      label: "#{oug.display_name} (#{ou_total}/#{pyr.org_units.size}) : #{sample_ous.join(', ')},..."
    }
  end

  @items = org_unit_groups
  render json: org_unit_groups
end

def organisation_unit_group_by_used_or_sibling_id
  pyr = Pyramid.new(current_project.dhis2_connection)
  sibling_id = current_project.entity_group.external_reference
  render_sol_items(pyr.find_sibling_organisation_unit_groups(sibling_id))
end

def render_sol_items(items)
  @items = items.map do |item|
    {
      type:  "option",
      value: item.id,
      label: item.display_name
    }
  end
  render json: @items
end
