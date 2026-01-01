# rubocop:disable Metrics/BlockLength:
namespace :tm do
  # rake 'tm:update_player_data_url[url]'
  desc 'Update player params by TM data from csv url'
  task :update_player_data_url, %i[url] => :environment do |_t, args|
    log_path = Rails.root.join('log/update_player_data_url.csv')
    FileUtils.mkdir_p(log_path.dirname)
    write_headers = !File.exist?(log_path) || File.empty?(log_path)

    csv = CSV.parse(URI.parse(args[:url]).open.read, headers: true)

    CSV.open(log_path, 'a', write_headers: write_headers, headers: %w[
               player_id player_name nationality_before nationality_after tm_price_before tm_price_after
               number_before number_after birth_date_before birth_date_after height_before height_after'
             ]) do |log_csv|
      csv.each do |player_data|
        player = Player.find_by(id: player_data['id'])
        next unless player

        attrs = player_data.to_h.slice('nationality', 'tm_price', 'number', 'birth_date', 'height').compact_blank

        attrs['number'] = attrs['number'].to_i if attrs['number']
        attrs['height'] = attrs['height'].to_i if attrs['height']
        attrs['tm_price'] = attrs['tm_price'].to_i if attrs['tm_price']

        changes = {}

        attrs.each do |key, new_value|
          current_value = player.public_send(key)
          comparable_current = current_value.is_a?(BigDecimal) ? current_value.to_i : current_value
          comparable_new = new_value

          next if comparable_current == comparable_new

          changes[key] = [current_value, new_value]
        end

        next if changes.empty?

        row = []
        row << player.id
        row << "#{player.first_name} #{player.name}"
        %w[nationality tm_price number birth_date height].each do |field|
          before, after = changes[field]
          row << (before.respond_to?(:to_s) ? before.to_s : before)
          row << (after.respond_to?(:to_s) ? after.to_s : after)
        end
        log_csv << row

        player.update!(changes.transform_values { |(_, new_val)| new_val })
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
