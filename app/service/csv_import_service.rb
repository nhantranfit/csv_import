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
      @firestore.transaction do |tx|
        line_number = 1
        CSV.foreach(@file, headers: true, encoding: 'bom|utf-8') do |row|
          line_number += 1
          material = parse_row(line_number, row)

          raise CsvImportServiceError, material[:error] unless material[:valid]

          if imported_materials.include?(material[:data][:material_name])
            raise CsvImportServiceError, "Duplicate material name: #{material[:data][:material_name]} in line #{line_number}. Please recheck this file."
          end

          # Kiểm tra tính duy nhất của standard_unit và standard_unit_cost
          if standard_unit_and_cost_exists_in_firestore?(material[:data][:standard_unit], material[:data][:standard_unit_cost])
            raise CsvImportServiceError, "Duplicate standard unit or standard unit cost in Firestore at line #{line_number}.
                                            Please recheck this file."
          end

          tx.set(@firestore.doc("materials/#{SecureRandom.uuid}"), material[:data])
          imported_materials << material[:data][:material_name]
          @processed_count += 1
        end
      end

      { success: true, message: "Successfully imported #{@processed_count} rows." }
    rescue CsvImportServiceError => e
      { success: false, errors: [e.message] }
    rescue StandardError => e
      { success: false, errors: ["Unexpected error: #{e.message}"] }
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
      { valid: false,
        error: "Material name (品目名1) cannot be empty in line #{line_number}. Please recheck this file!" }
    elsif material_exists_in_firestore_by_name?(material_data[:material_name])
      { valid: false,
        error: "Duplicate material name in Firestore: #{material_data[:material_name]} in line #{line_number}. Please recheck this file." }
    elsif standard_unit_and_cost_exists_in_firestore?(material_data[:standard_unit], material_data[:standard_unit_cost])
      { valid: false,
        error: "Duplicate standard unit or standard unit cost in Firestore in line #{line_number}. Please recheck this file." }
    else
      { valid: true, data: material_data }
    end
  end

  def material_exists_in_firestore_by_name?(material_name)
    result = @firestore.collection('materials').where('material_name', '==', material_name).limit(1).get
    result.any?
  rescue StandardError => e
    @errors << "Error while checking Firestore for material '#{material_name}': #{e.message}"
    false
  end

  # Kiểm tra tính duy nhất của standard_unit và standard_unit_cost
  def standard_unit_and_cost_exists_in_firestore?(standard_unit, standard_unit_cost)
    result = @firestore.collection('materials')
                        .where('standard_unit', '==', standard_unit)
                        .where('standard_unit_cost', '==', standard_unit_cost)
                        .limit(1)
                        .get
    result.any?
  rescue StandardError => e
    @errors << "Error while checking Firestore for standard unit '#{standard_unit}' and standard unit cost '#{standard_unit_cost}': #{e.message}"
    false
  end
end
