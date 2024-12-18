class Material < ApplicationRecord
  validates :material_name, presence: true, uniqueness: { scope: :standard_unit }
  validates :material_item_name2, uniqueness: { scope: :standard_unit }, if: -> { material_item_name2.present? }
  validates :standard_unit, presence: true
  validates :standard_unit_cost, numericality: { greater_than_or_equal_to: 0 }
end
