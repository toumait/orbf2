
class Pyramid
  def initialize(dhis2)
    org_unit_groups = dhis2.organisation_unit_groups
                           .list(fields: "id,displayName", page_size: 20_000)
    @org_unit_groups_by_id = org_unit_groups.index_by(&:id)

    org_units = dhis2.organisation_units
                     .list(fields: "id,displayName,organisationUnitGroups", page_size: 50_000)

    @org_units_by_id = org_units.index_by(&:id)

    org_units_by_group = {}
    org_units.each do |ou|
      next unless ou.organisation_unit_groups
      ou.organisation_unit_groups.each do |group|
        org_units_by_group[group["id"]] ||= Set.new
        org_units_by_group[group["id"]].add(ou)
      end
    end
    @org_units_by_group = org_units_by_group
  end

  def org_units
    @org_units_by_id.values
  end

  def org_unit_groups
    @org_unit_groups_by_id.values
  end

  def org_units_in_group(group_id)
    @org_units_by_group[group_id] || Set.new
  end

  def find_sibling_organisation_unit_groups(group_id)
    units = org_units

    sibling_group_ids = units.reject { |unit| unit.organisation_unit_groups.nil? }
                             .select { |unit| unit.organisation_unit_groups.any? { |g| g["id"] == group_id } }
                             .map(&:organisation_unit_groups)
                             .flatten
                             .map { |g| g["id"] }
                             .uniq
    sibling_group_ids -= [group_id]
    sibling_group_ids.map { |group_id| @org_unit_groups_by_id[group_id] }
  end
end