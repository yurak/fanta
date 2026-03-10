RSpec.describe PositionsHelper do
  let(:position) { Position.find_by!(name: Position::GOALKEEPER) }

  describe '#position_name' do
    context 'without current_user' do
      before { allow(helper).to receive(:current_user).and_return(nil) }

      it 'returns human_name' do
        expect(helper.position_name(position)).to eq(position.human_name)
      end
    end

    context 'with user with ital_pos_naming' do
      before { allow(helper).to receive(:current_user).and_return(create(:user, ital_pos_naming: true)) }

      it 'returns italian name' do
        expect(helper.position_name(position)).to eq(position.name)
      end
    end

    context 'with user without ital_pos_naming' do
      before { allow(helper).to receive(:current_user).and_return(create(:user, ital_pos_naming: false)) }

      it 'returns human_name' do
        expect(helper.position_name(position)).to eq(position.human_name)
      end
    end
  end

  describe '#slot_position_name' do
    context 'without current_user' do
      before { allow(helper).to receive(:current_user).and_return(nil) }

      it 'returns classic mapped name' do
        expect(helper.slot_position_name(Position::GOALKEEPER)).to eq(Slot::POS_MAPPING[Position::GOALKEEPER])
      end
    end

    context 'with user with ital_pos_naming' do
      before { allow(helper).to receive(:current_user).and_return(create(:user, ital_pos_naming: true)) }

      it 'returns position name unchanged' do
        expect(helper.slot_position_name(Position::GOALKEEPER)).to eq(Position::GOALKEEPER)
      end
    end

    context 'with user without ital_pos_naming' do
      before { allow(helper).to receive(:current_user).and_return(create(:user, ital_pos_naming: false)) }

      it 'returns classic mapped name' do
        expect(helper.slot_position_name(Position::GOALKEEPER)).to eq(Slot::POS_MAPPING[Position::GOALKEEPER])
      end
    end
  end

  describe '#modules_path' do
    context 'without current_user' do
      before { allow(helper).to receive(:current_user).and_return(nil) }

      it 'returns classic path' do
        expect(helper.modules_path).to eq('modules/classic/')
      end
    end

    context 'with user with ital_pos_naming' do
      before { allow(helper).to receive(:current_user).and_return(create(:user, ital_pos_naming: true)) }

      it 'returns ital path' do
        expect(helper.modules_path).to eq('modules/ital/')
      end
    end

    context 'with user without ital_pos_naming' do
      before { allow(helper).to receive(:current_user).and_return(create(:user, ital_pos_naming: false)) }

      it 'returns classic path' do
        expect(helper.modules_path).to eq('modules/classic/')
      end
    end
  end
end