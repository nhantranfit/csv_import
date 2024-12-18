class CreateMaterials < ActiveRecord::Migration[7.0]
  def change
    create_table :materials do |t|
      t.string :created_by
      t.string :material_name
      t.string :material_item_name2
      t.string :standard_unit
      t.decimal :standard_unit_cost
      t.string :updated_by

      t.timestamps
    end
  end
end
