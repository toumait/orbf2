# == Schema Information
#
# Table name: package_entity_groups
#
#  id                              :integer          not null, primary key
#  name                            :string
#  package_id                      :integer
#  organisation_unit_group_ext_ref :string
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#

class PackageEntityGroup < ApplicationRecord
  include PaperTrailed
  delegate :project_id, to: :package
  delegate :program_id, to: :package

  belongs_to :package
end
