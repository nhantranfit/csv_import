class MaterialsController < ApplicationController
  before_action :firestore, only: [:index, :delete_all_imported]
  def index
    materials = @firestore.collection('materials').get

    @materials = materials.map { |material| material.data }
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
    @firestore.batch do |batch|
        materials_collection = firestore.collection('materials').get
        materials_collection.each do |material|
          batch.delete(material.reference)
        end
      end
    render json: { success: true, message: 'All imported materials have been deleted.' }, status: :ok
  rescue Google::Cloud::Error => e
    render json: { success: false, message: "Error deleting materials: #{e.message}" }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { success: false, message: "Error: #{e.message}" }, status: :unprocessable_entity
  end

  private

  def firestore
    @firestore = FirestoreClient
  end
end
