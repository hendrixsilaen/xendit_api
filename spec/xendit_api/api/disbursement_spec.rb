require 'spec_helper'
require 'securerandom'

RSpec.describe XenditApi::Api::Disbursement do
  let(:client) { XenditApi::Client.new }

  describe '#create' do
    context 'with valid params' do
      it 'returns expected response' do
        VCR.use_cassette('xendit/disbursement/create/success') do
          disbursement_api = described_class.new(client)
          response = disbursement_api.create(
            external_id: SecureRandom.uuid,
            amount: 15_000,
            bank_code: 'BCA',
            account_holder_name: 'Bob Jones',
            account_number: '1111111111',
            disbursement_description: 'Payment'
          )
          expect(response).to be_instance_of XenditApi::Model::Disbursement
          expect(response).to have_attributes(
            amount: 15_000,
            bank_code: 'BCA',
            account_holder_name: 'Bob Jones',
            status: 'PENDING',
            disbursement_description: 'sample disbursement'
          )
          expect(response.external_id).not_to be_nil
          expect(response.id).not_to be_nil
        end
      end
    end

    context 'with invalid params' do
      it 'raise errors when bank code not registered' do
        error_payload = { 'error_code' => 'BANK_CODE_NOT_SUPPORTED_ERROR', 'message' => 'Bank code is not supported' }
        VCR.use_cassette('xendit/disbursement/create/bank_code_not_supported_error') do
          disbursement_api = described_class.new(client)
          expect do
            disbursement_api.create(
              external_id: SecureRandom.uuid,
              amount: 15_000,
              bank_code: 'NOT_FOUND',
              account_holder_name: 'Bob Jones',
              account_number: '1111111111',
              disbursement_description: 'sample disbursement'
            )
          end.to raise_error do |error|
            expect(error).to be_kind_of(XenditApi::Errors::Disbursement::BankCodeNotSupported)
            expect(error.message).to eq 'Bank code is not supported'
            expect(error.payload).to eq error_payload
          end
        end
      end

      it 'raise errors when got DISBURSEMENT_DESCRIPTION_NOT_FOUND_ERROR' do
        error_payload = { 'error_code' => 'DISBURSEMENT_DESCRIPTION_NOT_FOUND_ERROR', 'message' => 'Direct disbursement not found' }
        VCR.use_cassette('xendit/disbursement/create/disbursement_description_not_found_error') do
          disbursement_api = described_class.new(client)
          expect do
            disbursement_api.create(
              external_id: SecureRandom.uuid,
              amount: 15_000,
              bank_code: 'BCA',
              account_holder_name: 'Bob Jones',
              account_number: '1111111111',
              disbursement_description: nil
            )
          end.to raise_error do |error|
            expect(error).to be_kind_of XenditApi::Errors::Disbursement::DescriptionNotFound
            expect(error.message).to eq 'Direct disbursement not found'
            expect(error.payload).to eq error_payload
          end
        end
      end

      it 'raise errors when got DIRECT_DISBURSEMENT_BALANCE_INSUFFICIENT_ERROR' do
        error_payload = { 'error_code' => 'DIRECT_DISBURSEMENT_BALANCE_INSUFFICIENT_ERROR', 'message' => 'Balance is insufficient' }
        VCR.use_cassette('xendit/disbursement/create/disbursement_not_enough_balance_error') do
          disbursement_api = described_class.new(client)
          expect do
            disbursement_api.create(
              external_id: SecureRandom.uuid,
              amount: 1_000_000_000_000,
              bank_code: 'BCA',
              account_holder_name: 'Bob Jones',
              account_number: '1111111111',
              disbursement_description: 'sample disbursement'
            )
          end.to raise_error do |error|
            expect(error).to be_kind_of XenditApi::Errors::Disbursement::NotEnoughBalance
            expect(error.message).to eq 'Balance is insufficient'
            expect(error.payload).to eq error_payload
          end
        end
      end

      it 'raise erorrs when got DUPLICATE_TRANSACTION_ERROR' do
        error_payload = { 'error_code' => 'DUPLICATE_TRANSACTION_ERROR', 'message' => 'Disbursement was duplicated' }
        VCR.use_cassette('xendit/disbursement/create/duplicate_transaction_error') do
          disbursement_api = described_class.new(client)
          expect do
            disbursement_api.create(
              external_id: SecureRandom.uuid,
              amount: 100_000,
              bank_code: 'BCA',
              account_holder_name: 'Bob Jones',
              account_number: '1111111111',
              disbursement_description: 'sample disbursement'
            )
          end.to raise_error do |error|
            expect(error).to be_kind_of XenditApi::Errors::Disbursement::DuplicateTransactionError
            expect(error.message).to eq 'Disbursement was duplicated'
            expect(error.payload).to eq error_payload
          end
        end
      end

      it 'raise error when got RECIPIENT_ACCOUNT_NUMBER_ERROR' do
        error_payload = { 'error_code' => 'RECIPIENT_ACCOUNT_NUMBER_ERROR', 'message' => 'BCA account numbers must be 10 digits long' }
        VCR.use_cassette('xendit/disbursement/create/recipient_account_number_error') do
          disbursement_api = described_class.new(client)
          expect do
            disbursement_api.create(
              external_id: SecureRandom.uuid,
              amount: 100_000,
              bank_code: 'BCA',
              account_holder_name: 'Bob Jones',
              account_number: '123',
              disbursement_description: 'sample disbursement'
            )
          end.to raise_error do |error|
            expect(error).to be_kind_of XenditApi::Errors::Disbursement::RecipientAccountNumberError
            expect(error.message).to eq 'BCA account numbers must be 10 digits long'
            expect(error.payload).to eq error_payload
          end
        end
      end

      it 'raise error when got RECIPIENT_AMOUNT_ERROR' do
        error_payload = { 'error_code' => 'RECIPIENT_AMOUNT_ERROR', 'message' => 'Recipient amount error' }
        VCR.use_cassette('xendit/disbursement/create/recipient_amount_error') do
          disbursement_api = described_class.new(client)
          expect do
            disbursement_api.create(
              external_id: SecureRandom.uuid,
              amount: 1,
              bank_code: 'BCA',
              account_holder_name: 'Bob Jones',
              account_number: '1111111111',
              disbursement_description: 'sample disbursement'
            )
          end.to raise_error do |error|
            expect(error).to be_kind_of XenditApi::Errors::Disbursement::RecipientAmountError
            expect(error.message).to eq 'Recipient amount error'
            expect(error.payload).to eq error_payload
          end
        end
      end

      it 'raise error when got MAXIMUM_TRANSFER_LIMIT_ERROR' do
        error_payload = { 'error_code' => 'MAXIMUM_TRANSFER_LIMIT_ERROR', 'message' => 'Maximum transfer limit error' }
        VCR.use_cassette('xendit/disbursement/create/maximum_transfer_limit_error') do
          disbursement_api = described_class.new(client)
          expect do
            disbursement_api.create(
              external_id: SecureRandom.uuid,
              amount: 10_000_000,
              bank_code: 'BCA',
              account_holder_name: 'Bob Jones',
              account_number: '1111111111',
              disbursement_description: 'sample disbursement'
            )
          end.to raise_error do |error|
            expect(error).to be_kind_of XenditApi::Errors::Disbursement::MaximumTransferLimitError
            expect(error.message).to eq 'Maximum transfer limit error'
            expect(error.payload).to eq error_payload
          end
        end
      end
    end
  end

  describe '#find_by_external_id' do
    context 'with valid external_id' do
      it 'returns exected response' do
        VCR.use_cassette('xendit/disbursement/find_by_external_id/200_ok') do
          disbursement_api = described_class.new(client)
          disbursement = disbursement_api.find_by_external_id('d28aac6a-03c8-46d0-ac03-43b6278b35eb')
          expect(disbursement).to be_kind_of XenditApi::Model::Disbursement
          expect(disbursement.external_id).to eq 'd28aac6a-03c8-46d0-ac03-43b6278b35eb'
          expect(disbursement.amount).not_to be_nil
          expect(disbursement.bank_code).not_to be_nil
          expect(disbursement.user_id).not_to be_nil
          expect(disbursement.account_holder_name).not_to be_nil
          expect(disbursement.status).not_to be_nil
          expect(disbursement.id).not_to be_nil
          expect(disbursement.payload).not_to be_nil
        end
      end
    end

    context 'with invalid external id' do
      it 'returns expected response' do
        error_payload = { 'error_code' => 'DIRECT_DISBURSEMENT_NOT_FOUND_ERROR', 'message' => 'Direct disbursement not found' }
        VCR.use_cassette('xendit/disbursement/find_by_external_id/invalid') do
          disbursement_api = described_class.new(client)

          expect do
            disbursement_api.find_by_external_id('d666')
          end.to raise_error do |error|
            expect(error).to be_kind_of XenditApi::Errors::Disbursement::DirectDisbursementNotFound
            expect(error.message).to eq 'Direct disbursement not found'
            expect(error.payload).to eq error_payload
          end
        end
      end
    end
  end
end
