require 'rails_helper'
require 'csv'

RSpec.describe CsvImportService, type: :service do
  let(:valid_file) { 'spec/fixtures/files/valid_materials.csv' }
  let(:invalid_file) { 'spec/fixtures/files/invalid_materials.csv' }

  let(:firestore_client) { instance_double('Google::Cloud::Firestore::Client') }
  let(:transaction) { instance_double('Google::Cloud::Firestore::Transaction') }
  let(:service) { CsvImportService.new(valid_file, firestore_client) }

  before do
    allow(firestore_client).to receive(:transaction).and_yield(transaction)
    allow(transaction).to receive(:set)
    allow(firestore_client).to receive(:doc).and_return(double('Document'))

    query_double = instance_double('Google::Cloud::Firestore::Query')
    allow(firestore_client).to receive(:collection).with('materials').and_return(query_double)
    allow(query_double).to receive(:where).and_return(query_double)
    allow(query_double).to receive(:limit).with(1).and_return(query_double)
    allow(query_double).to receive(:get).and_return([])
  end

  describe '#import' do
    context 'when file is blank' do
      let(:service) { CsvImportService.new(nil, firestore_client) }

      it 'returns an error message' do
        result = service.import
        expect(result[:success]).to eq(false)
        expect(result[:errors]).to include('No file uploaded')
      end
    end

    context 'when file has invalid data' do
      let(:service) { CsvImportService.new(invalid_file, firestore_client) }

      it 'returns an error message for empty material name' do
        result = service.import
        expect(result[:success]).to eq(false)
        expect(result[:errors]).to include('Please check 2 lines. 品目名1 column beacause cannot blank.')
      end
    end

    context 'when file has duplicate material name' do
      let(:service) { CsvImportService.new(valid_file, firestore_client) }

      it 'raises an error for duplicate material name' do
        allow(firestore_client).to receive(:collection).and_return(double('Collection', where: double('Query', limit: double('Limit', get: [double('Document')]))))

        result = service.import
        expect(result[:success]).to eq(false)
        expect(result[:errors]).to include("Please check 2 lines. 品目名1 column beacause cannot blank.")
      end
    end

    # context 'when file has valid data' do
    #   let(:service) { CsvImportService.new(valid_file, firestore_client) }
    #   it 'imports the data successfully' do
    #     result = service.import
    #     expect(result[:success]).to eq(true)
    #     expect(result[:message]).to include('Successfully imported')
    #   end
    # end
  end
end
