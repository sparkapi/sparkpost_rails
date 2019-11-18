require 'spec_helper'

describe SparkPostRails::DeliveryMethod do
  subject { described_class.new }
  let(:metadata) { {item_1: 'test data 1', item_2: 'test data 2'} }

  describe 'Metadata' do
    context 'template-based message' do
      context 'when metadata is passed' do
        it 'includes metadata' do
          test_email = Mailer.test_email sparkpost_data: { template_id: 'test_template', metadata: metadata }
          subject.deliver!(test_email)
          expect(subject.data[:metadata]).to eq(metadata)
        end
      end

      context "when metadata isn't passed" do
        it "doesn't include metadata" do
          test_email = Mailer.test_email sparkpost_data: { template_id: 'test_template' }
          subject.deliver!(test_email)
          expect(subject.data).to_not have_key(:metadata)
        end
      end
    end

    context 'inline-content message' do
      context 'when metadata is passed' do
        it 'includes metadata' do
          test_email = Mailer.test_email sparkpost_data: { metadata: metadata }
          subject.deliver!(test_email)
          expect(subject.data[:metadata]).to eq(metadata)
        end
      end

      context "when metadata isn't passed" do
        it "doesn't include metadata" do
          test_email = Mailer.test_email sparkpost_data: { metadata: nil }
          subject.deliver!(test_email)
          expect(subject.data).to_not have_key(:metadata)
        end
      end

      context "metadata passed to DeliveryMethod constructor" do
        let(:api_key) { 'test_api_key' }

        it "uses the DeliveryMethod metadata if no metadata is passed with the mailer call", skip_configure: true, skip_api_request_stub: true do
          test_email = Mailer.test_email
          test_email.delivery_method described_class, { api_key: api_key, metadata: metadata }

          api_request = stub_request(:post, "https://api.sparkpost.com/api/v1/transmissions").
            with(
              body: '{"content":{"from":{"email":"from@example.com"},"subject":"Test Email","text":"Hello, Testing!"},"recipients":[{"address":{"email":"to@example.com","header_to":"to@example.com"}}],"metadata":{"item_1":"test data 1","item_2":"test data 2"},"options":{"open_tracking":false,"click_tracking":false,"transactional":false,"inline_css":false}}',
              headers: {
                'Accept' => '*/*',
                'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'Authorization' => api_key,
                'Content-Type' => 'application/json',
                'User-Agent' => 'Ruby'
              }
          ).to_return(status: 200, body: "{\"results\":{\"total_rejected_recipients\":0,\"total_accepted_recipients\":1,\"id\":\"00000000000000000\"}}", headers: {})

          test_email.deliver!

          assert_requested api_request
        end
      end
    end
  end
end
