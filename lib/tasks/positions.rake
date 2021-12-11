namespace :positions do
  desc 'Update position names and locations'
  task new_names: :environment do
    # TODO: uncomment after adding human_name to Positions
    # names = YAML.load_file(Rails.root.join('config/mantra/position_names.yml'))
    # Position.all.each do |position|
    #   position.update(human_name: names[position.name])
    # end

    csv_text = File.read('config/mantra/slots_location.csv')
    CSV.parse(csv_text, headers: false).each do |location_data|
      slot = Slot.find(location_data[0])
      slot.update(location: location_data[1])
    end
  end
end
