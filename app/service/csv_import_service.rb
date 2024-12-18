require 'csv'

class CsvImportService
  class CsvImportServiceError < StandardError; end
  def initialize(file)
    @file = file
    @errors = []
    @processed_count = 0
  end

  def import
    return { success: false, errors: ["No file uploaded"] } if @file.blank?

    begin
      ActiveRecord::Base.transaction do
        line_number = 1
        CSV.foreach(@file, headers: true, encoding: 'bom|utf-8') do |row|
          line_number += 1
          material = parse_row(line_number, row)
          if material[:valid]
            Material.create!(material[:data])
            @processed_count += 1
          else
            raise CsvImportServiceError, material[:error]
          end
        end
      end

      { success: true, message: "Successfully imported #{@processed_count} rows." }
    rescue CsvImportServiceError => e
      { success: false, errors: [e.message] }
    rescue StandardError => e
      { success: false, errors: ["#{e.message}"] }
    end
  end

  private

  def parse_row(line_number, row)
    material_data = {
      material_name: row['品目名1'],
      material_item_name2: row['品目名2'],
      standard_unit: row['標準単位'],
      standard_unit_cost: row['標準単価'].to_f,
      created_at: Time.current,
      created_by: 'CSV',
      updated_at: Time.current,
      updated_by: 'CSV'
    }
    handle_conditional(line_number, material_data)
  end

  def handle_conditional(line_number, material_data)
    if material_data[:material_name].blank?
      { valid: false, error: "Material name (品目名1) cannot be empty in line #{line_number}. Please recheck this file!" }
    elsif Material.exists?(material_name: material_data[:material_name])
      { valid: false, error: "Duplicate material name: #{material_data[:material_name]} in line #{line_number}. Please recheck this file." }
    elsif Material.exists?(material_item_name2: material_data[:material_item_name2]) && material_data[:material_item_name2].present?
      { valid: false, error: "Duplicate material name: #{material_data[:material_name]} in line #{line_number}. Please recheck this file."}
    else
      { valid: true, data: material_data }
    end
  end

end
