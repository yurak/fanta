RSpec.describe Teams::LogoUploader do
  subject(:upload) { described_class.call(user: user, file: file) }

  let(:user) { create(:user) }
  let(:content_type) { 'image/png' }
  let(:size) { 1.megabyte }
  let(:file) { instance_double(ActionDispatch::Http::UploadedFile, content_type: content_type, size: size, read: 'bytes') }
  let(:s3_client) { instance_double(Aws::S3::Client, put_object: nil) }
  let(:bucket) { 'test-bucket' }
  let(:bucket_url) { 'https://test-bucket.example.com' }

  before do
    image = instance_double(MiniMagick::Image, width: 300, height: 400, to_blob: 'png-bytes')
    allow(image).to receive(:combine_options)
    allow(image).to receive(:format)
    allow(MiniMagick::Image).to receive(:read).and_return(image)
    allow(S3Storage).to receive_messages(client: s3_client, bucket: bucket, bucket_url: bucket_url)
  end

  context 'with a valid image' do
    it 'creates a UserLogo for the user' do
      expect { upload }.to change(user.user_logos, :count).by(1)
    end

    it 'records it as pending' do
      expect(upload).to be_pending
    end

    it 'stores the url under the user prefix' do
      expect(upload.url).to match(%r{\A#{Regexp.escape(bucket_url)}/user_logos/#{user.id}/[a-f0-9]+\.png\z})
    end

    it 'uploads a png to S3' do
      upload
      expect(s3_client).to have_received(:put_object).with(hash_including(bucket: bucket, content_type: 'image/png'))
    end
  end

  context 'with an unsupported file type' do
    let(:content_type) { 'application/pdf' }

    it { expect { upload }.to raise_error(described_class::InvalidFile) }
  end

  context 'when the file is too large' do
    let(:size) { 6.megabytes }

    it { expect { upload }.to raise_error(described_class::InvalidFile) }
  end

  context 'when the bytes are not a valid image' do
    before do
      allow(MiniMagick::Image).to receive(:read).and_raise(MiniMagick::Invalid)
    end

    it { expect { upload }.to raise_error(described_class::InvalidFile) }
  end

  context 'when the user reached the logo limit' do
    before do
      create_list(:user_logo, described_class::MAX_LOGOS, user: user)
    end

    it { expect { upload }.to raise_error(described_class::InvalidFile) }

    it 'does not upload to S3' do
      suppress(described_class::InvalidFile) { upload }
      expect(s3_client).not_to have_received(:put_object)
    end
  end
end
