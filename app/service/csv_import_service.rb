class CsvImportService
  class CsvImportServiceError < StandardError; end

  def initialize(file, firestore_client = FirestoreClient)
    @file = file
    @errors = []
    @processed_count = 0
    @firestore = firestore_client
  end

  def import
    return { success: false, errors: ['No file uploaded'] } if @file.blank?

    begin
      imported_materials = []
      raw_content = File.read(@file, mode: 'rb')
                        .force_encoding('Shift_JIS')
                        .encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')

      temp_file = Rails.root.join('tmp', 'cleaned_file.csv')
      File.write(temp_file, raw_content)

      options = { file_encoding: 'UTF-8' }

      @firestore.transaction do |tx|
        line_number = 1
        SmarterCSV.process(temp_file, options) do |row|
          line_number += 1
          material = parse_row(line_number, row)
          raise CsvImportServiceError, material[:error] unless material[:valid]

          check_duplicate_value(imported_materials, material[:data], line_number)
          imported_materials << material[:data][:material_name]
          tx.set(@firestore.doc("materials/#{SecureRandom.uuid}"), material[:data])
          @processed_count += 1
        end
        delete_all_current_data(tx)

      end

      { success: true, message: "Successfully imported #{@processed_count} rows." }
    rescue CsvImportServiceError => e
      { success: false, errors: [e.message] }
    rescue StandardError => e
      { success: false, errors: ["Unexpected error: #{e.message}"] }
    end
  end

  private

  def check_duplicate_value(imported_materials, data, line_number)
    if imported_materials.include?(data[:material_name])
      raise CsvImportServiceError, "Please check #{line_number} lines. 品目名1 column because be duplicated"
    elsif imported_materials.include?(data[:material_item_name2])
      raise CsvImportServiceError, "Please check #{line_number} lines. 品目名2 column because be duplicated"
    elsif imported_materials.include?(data[:standard_unit]) && imported_materials.include?(data[:standard_unit_cost])
      raise CsvImportServiceError, "Please check #{line_number} lines. 標準単位 and 標準単価 column because be duplicated"
    end
  end

  def delete_all_current_data(transaction)
    materials_ref = @firestore.col('materials')
    materials_ref.get.each do |doc|
      transaction.delete(doc.ref)
    end
  end

  def parse_row(line_number, row)
    item = row.first

    material_data = {
      material_name: item[:品目名1],
      material_item_name2: item[:品目名2],
      standard_unit: item[:標準単位],
      standard_unit_cost: item[:標準単価].to_f,
      created_at: Time.current,
      created_by: 'CSV',
      updated_at: Time.current,
      updated_by: 'CSV'
    }

    validate_row(line_number, material_data)
  end

  def validate_row(line_number, material_data)
    if material_data[:material_name].blank?
      { valid: false,
        error: "Please check #{line_number} lines. 品目名1 column because cannot be blank." }
    elsif material_data[:standard_unit].blank?
      { valid: false,
        error: "Please check #{line_number} lines. 標準単位 column because cannot be blank." }
    else
      { valid: true, data: material_data }
    end
  end
end
