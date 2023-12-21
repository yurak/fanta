namespace :positions do
  # rake positions:new_names
  desc 'Update position names and locations'
  task new_names: :environment do
    Position.find_each do |position|
      position.update(human_name: Slot::POS_MAPPING[position.name])
    end

    # csv_text = File.read('config/mantra/slots_location.csv')
    # CSV.parse(csv_text, headers: false).each do |location_data|
    #   slot = Slot.find(location_data[0])
    #   slot.update(location: location_data[1])
    # end
  end
end
