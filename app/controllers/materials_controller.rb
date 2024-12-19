
class MaterialsController < ApplicationController
  def index
    materials = FirestoreClient.collection('materials').get

    @materials = materials.map { |doc| doc.data }

    @pagy, @materials = pagy_array(@materials)
  end

  def import_csv
    file = params[:file]

    service = CsvImportService.new(file)
    result = service.import

    if result[:success]
      render json: { message: result[:message] }, status: :ok
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  def delete_all_imported
    begin
      # Khởi tạo Firestore client
      firestore = Google::Cloud::Firestore.new

      # Khởi tạo batch và truyền block cho nó
      firestore.batch do |batch|
        # Lấy tất cả tài liệu từ collection 'materials'
        materials_ref = firestore.collection('materials')
        materials_ref.get.each do |doc|
          batch.delete(doc.reference)  # Thêm thao tác xóa vào batch
        end
      end

      render json: { success: true, message: "All imported materials have been deleted." }, status: :ok
    rescue Google::Cloud::Error => e
      render json: { success: false, message: "Error deleting materials: #{e.message}" }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { success: false, message: "Error: #{e.message}" }, status: :unprocessable_entity
    end
  end



end
