require 'rails_helper'

RSpec.describe MaterialsController, type: :controller do
  let(:firestore_client) { instance_double('Google::Cloud::Firestore::Client') }
  let(:firestore_collection) { instance_double('Google::Cloud::Firestore::CollectionReference') }
  let(:firestore_batch) { instance_double('Google::Cloud::Firestore::Batch') }
  let(:materials) do
    [
      double('Material', data: { name: 'Material A' }, reference: double('ReferenceA')),
      double('Material', data: { name: 'Material B' }, reference: double('ReferenceB'))
    ]
  end

  before do
    allow(FirestoreClient).to receive(:collection).and_return(firestore_collection)
  end

  describe 'GET #index' do
    before do
      allow(firestore_collection).to receive(:get).and_return(materials)
    end

    it 'retrieves and paginates materials from Firestore' do
      get :index
      expect(assigns(:materials)).to eq([{ name: 'Material A' }, { name: 'Material B' }])
      expect(response).to have_http_status(:ok)
    end

    context 'when there are no materials in Firestore' do
      before do
        allow(firestore_collection).to receive(:get).and_return([])
      end

      it 'returns an empty array' do
        get :index
        expect(assigns(:materials)).to eq([])
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST #import_csv' do
    let(:file) { fixture_file_upload('spec/fixtures/files/valid_materials.csv', 'text/csv') }
    let(:csv_import_service) { instance_double(CsvImportService) }

    before do
      allow(CsvImportService).to receive(:new).and_return(csv_import_service)
    end

    context 'when import is successful' do
      before do
        allow(csv_import_service).to receive(:import).and_return({ success: true, message: 'Import successful' })
      end

      it 'returns a success message' do
        post :import_csv, params: { file: file }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Import successful')
      end
    end

    context 'when import fails' do
      before do
        allow(csv_import_service).to receive(:import).and_return({ success: false, errors: ['File is invalid'] })
      end

      it 'returns an error message' do
        post :import_csv, params: { file: file }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include('File is invalid')
      end
    end

  end

  describe 'DELETE #delete_all_imported' do
    before do
      allow(FirestoreClient).to receive(:batch).and_yield(firestore_batch)
      allow(firestore_collection).to receive(:get).and_return(materials)
      allow(firestore_batch).to receive(:delete)
    end

    context 'when deletion is successful' do
      it 'deletes all materials and returns a success message' do
        delete :delete_all_imported

        expect(firestore_batch).to have_received(:delete).twice
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('All imported materials have been deleted.')
      end
    end

    context 'when an error occurs during deletion' do
      before do
        allow(firestore_collection).to receive(:get).and_raise(Google::Cloud::Error, 'Firestore error')
      end

      it 'returns an error message' do
        delete :delete_all_imported

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['message']).to include('Firestore error')
      end
    end

    context 'when a standard error occurs' do
      before do
        allow(firestore_collection).to receive(:get).and_raise(StandardError, 'Unexpected error')
      end

      it 'returns an error message' do
        delete :delete_all_imported

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['message']).to include('Unexpected error')
      end
    end
  end
end
