# rubocop:disable Metrics/BlockLength
require 'aws-sdk-s3'

TM_CLUB_API_URL = 'https://tmapi-alpha.transfermarkt.technology/club'.freeze
CLUB_TRANSFERS_S3_BUCKET = 'mantrafootball'.freeze
CLUB_TRANSFERS_S3_PREFIX = 'club_transfers'.freeze
CLUB_TRANSFERS_NON_CLUB_NAMES = %w[Retired].freeze
CLUB_TRANSFERS_CSV_HEADERS = %w[
  player_id player_name current_club_id current_club_name
  tm_club_id new_club_id new_club_name club_joined_on contract_until loan
].freeze

module ClubTransfersTasks
  def self.s3_client
    aws = Rails.application.credentials.aws
    Aws::S3::Client.new(
      region: aws[:region] || 'eu-west-1',
      access_key_id: aws[:access_key_id],
      secret_access_key: aws[:secret_access_key]
    )
  end

  def self.upload_to_s3(local_path, s3_key)
    File.open(local_path, 'rb') do |file|
      s3_client.put_object(bucket: CLUB_TRANSFERS_S3_BUCKET, key: s3_key, body: file)
    end
    "https://#{CLUB_TRANSFERS_S3_BUCKET}.s3.eu-west-1.amazonaws.com/#{s3_key}"
  end

  def self.download_from_s3(url)
    key = URI.parse(url).path.sub(%r{^/}, '')
    tmp = Tempfile.new(['club_transfers', '.csv'])
    response = s3_client.get_object(bucket: CLUB_TRANSFERS_S3_BUCKET, key: key)
    tmp.write(response.body.read)
    tmp.rewind
    tmp
  rescue StandardError => e
    tmp&.close
    tmp&.unlink
    raise e
  end

  def self.fetch_tm_club_name(tm_club_id)
    response = RestClient::Request.execute(
      method: :get,
      url: "#{TM_CLUB_API_URL}/#{tm_club_id}",
      headers: {
        'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0',
        'Accept' => 'application/json'
      },
      verify_ssl: false
    )
    JSON.parse(response.body).dig('data', 'name')
  rescue StandardError
    "TM Club ##{tm_club_id}"
  end
end

namespace :club_transfers do
  # rake 'club_transfers:fetch_data[1000,2000]'
  desc 'Fetch TM club data for players (optional from_id/to_id), upload CSV to S3'
  task :fetch_data, %i[from_id to_id] => :environment do |_t, args|
    from_id = args[:from_id]&.to_i
    to_id   = args[:to_id]&.to_i

    timestamp    = Time.zone.now.strftime('%Y%m%d_%H%M%S')
    range_suffix = [from_id, to_id].any? { |v| v&.positive? } ? "_#{from_id}_#{to_id}" : ''
    s3_key       = "#{CLUB_TRANSFERS_S3_PREFIX}/data_#{timestamp}#{range_suffix}.csv"
    local_path   = Rails.root.join("tmp/club_transfers_#{timestamp}.csv")

    players = Player.where.not(tm_id: nil).order(:id)
    players = players.where('players.id >= ?', from_id) if from_id&.positive?
    players = players.where('players.id <= ?', to_id)   if to_id&.positive?

    changed_count = 0

    CSV.open(local_path, 'w') do |csv|
      csv << CLUB_TRANSFERS_CSV_HEADERS

      players.find_each do |player|
        p "Checking player #{player.id} / #{player.name}"

        begin
          data = Players::Transfermarkt::ApiParser.call(player.tm_id)
          next unless data

          tm_club_id = data[:tm_club_id]
          next if tm_club_id.blank?

          current_tm_club_id = player.club&.tm_id
          reserve_ids = player.club&.reserve_club_ids.to_a
          next if tm_club_id == current_tm_club_id || reserve_ids.include?(tm_club_id)

          new_club_id   = data[:club_id]
          new_club_name = if new_club_id
                            Club.find_by(id: new_club_id)&.name || ClubTransfersTasks.fetch_tm_club_name(tm_club_id)
                          else
                            ClubTransfersTasks.fetch_tm_club_name(tm_club_id)
                          end

          old_club_name = player.club&.name
          if CLUB_TRANSFERS_NON_CLUB_NAMES.include?(old_club_name) &&
              CLUB_TRANSFERS_NON_CLUB_NAMES.include?(new_club_name)
            puts "#{player.name}: skipping #{old_club_name} → #{new_club_name}"
            next
          end

          csv << [
            player.id,
            player.name,
            player.club_id,
            player.club&.name,
            tm_club_id,
            new_club_id,
            new_club_name,
            data[:club_joined_on],
            data[:contract_until],
            data[:loan]
          ]

          changed_count += 1
          puts "#{player.name}: #{player.club&.name} → #{new_club_name} (joined: #{data[:club_joined_on]})"
        rescue StandardError => e
          puts "Error for player #{player.id} / #{player.tm_id}: #{e.message}"
        end
      end
    end

    url = ClubTransfersTasks.upload_to_s3(local_path, s3_key)
    File.delete(local_path)

    puts "Done. #{changed_count} players with club changes."
    puts "CSV uploaded to: #{url}"
  end

  # rake 'club_transfers:fetch_initial_data[1000,2000]'
  desc 'Fetch current TM club for ALL players (initial snapshot), upload CSV to S3'
  task :fetch_initial_data, %i[from_id to_id] => :environment do |_t, args|
    from_id = args[:from_id]&.to_i
    to_id   = args[:to_id]&.to_i

    timestamp    = Time.zone.now.strftime('%Y%m%d_%H%M%S')
    range_suffix = [from_id, to_id].any? { |v| v&.positive? } ? "_#{from_id}_#{to_id}" : ''
    s3_key       = "#{CLUB_TRANSFERS_S3_PREFIX}/initial_#{timestamp}#{range_suffix}.csv"
    local_path   = Rails.root.join("tmp/club_transfers_initial_#{timestamp}.csv")

    players = Player.where.not(tm_id: nil).order(:id)
    players = players.where('players.id >= ?', from_id) if from_id&.positive?
    players = players.where('players.id <= ?', to_id)   if to_id&.positive?

    saved_count = 0

    CSV.open(local_path, 'w') do |csv|
      csv << CLUB_TRANSFERS_CSV_HEADERS

      players.find_each do |player|
        p "Checking player #{player.id} / #{player.name}"

        begin
          data = Players::Transfermarkt::ApiParser.call(player.tm_id)
          next unless data

          tm_club_id = data[:tm_club_id]
          next if tm_club_id.blank?

          new_club_id   = data[:club_id]
          new_club_name = if new_club_id
                            Club.find_by(id: new_club_id)&.name || ClubTransfersTasks.fetch_tm_club_name(tm_club_id)
                          else
                            ClubTransfersTasks.fetch_tm_club_name(tm_club_id)
                          end

          next if CLUB_TRANSFERS_NON_CLUB_NAMES.include?(new_club_name)

          csv << [
            player.id,
            player.name,
            nil,
            nil,
            tm_club_id,
            new_club_id,
            new_club_name,
            data[:club_joined_on],
            data[:contract_until],
            data[:loan]
          ]

          saved_count += 1
          puts "#{player.name}: #{new_club_name} (joined: #{data[:club_joined_on]})"
        rescue StandardError => e
          puts "Error for player #{player.id} / #{player.tm_id}: #{e.message}"
        end
      end
    end

    url = ClubTransfersTasks.upload_to_s3(local_path, s3_key)
    File.delete(local_path)

    puts "Done. #{saved_count} players saved."
    puts "CSV uploaded to: #{url}"
  end

  # rake 'club_transfers:create_records[https://mantrafootball.s3.eu-west-1.amazonaws.com/club_transfers/data_....csv]'
  desc 'Create ClubTransfer records from CSV on S3 (required: url)'
  task :create_records, %i[url] => :environment do |_t, args|
    url = args[:url]
    abort 'Provide S3 URL as argument. Example: rake club_transfers:create_records[https://...]' if url.blank?

    created_count = 0
    skipped_count = 0

    tmp = ClubTransfersTasks.download_from_s3(url)

    begin
      CSV.foreach(tmp.path, headers: true) do |row|
        player = Player.find_by(id: row['player_id'])
        unless player
          puts "Player #{row['player_id']} not found, skipping"
          next
        end

        new_club_id = row['new_club_id'].presence&.to_i
        start_date  = row['club_joined_on'].presence || Time.zone.today.to_s

        exists_scope = { player: player, start_date: start_date }
        exists_scope = if new_club_id
                         exists_scope.merge(new_club_id: new_club_id)
                       else
                         exists_scope.merge(new_club_name: row['new_club_name'])
                       end
        if ClubTransfer.exists?(exists_scope)
          skipped_count += 1
          next
        end

        ClubTransfer.create!(
          player: player,
          old_club_id: row['current_club_id'].presence&.to_i,
          old_club_name: row['current_club_name'],
          new_club_id: new_club_id,
          new_club_name: row['new_club_name'],
          start_date: start_date,
          contract_expires_on: row['contract_until'].presence,
          loan: row['loan'] == 'true'
        )

        created_count += 1
        puts "Created: #{row['player_name']} → #{row['new_club_name']} (#{start_date})"
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        puts "Error for player #{row['player_name']}: #{e.message}"
      end
    ensure
      tmp.close
      tmp.unlink
    end

    puts "Done. Created: #{created_count}, skipped: #{skipped_count}"
  end
end
# rubocop:enable Metrics/BlockLength
