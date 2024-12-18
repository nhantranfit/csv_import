class MaterialsController < ApplicationController
  def index
    @pagy, @materials = pagy(Material.order(created_at: :desc))
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
end
