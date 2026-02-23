# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notification do
  describe 'associations' do
    it { is_expected.to belong_to(:team) }
    it { is_expected.to belong_to(:notifiable) }
  end

  describe 'constants' do
    it 'defines PENDING' do
      expect(described_class::PENDING).to eq('pending')
    end
  end

  describe 'enums' do
    let(:team) { create(:team) }
    let(:tour) { create(:tour) }

    let!(:pending_opened_normal) do
      create(:notification, team: team, notifiable: tour, status: :pending, kind: :tour_opened, priority: :normal)
    end

    let!(:sent_closed_high) do
      create(:notification, team: team, notifiable: tour, status: :sent, kind: :tour_closed, priority: :high)
    end

    it 'defines status enum mapping' do
      expect(described_class.statuses).to eq('pending' => 0, 'sent' => 1, 'failed' => 2)
    end

    it 'defines kind enum mapping' do
      expect(described_class.kinds).to eq('tour_opened' => 0, 'tour_ddl' => 1, 'tour_moderated' => 2, 'tour_closed' => 3)
    end

    it 'defines priority enum mapping' do
      expect(described_class.priorities).to eq('low' => 0, 'normal' => 1, 'high' => 2, 'critical' => 3)
    end

    it 'scopes by pending status' do
      expect(described_class.pending).to include(pending_opened_normal)
    end

    it 'scopes by pending status and does not include other' do
      expect(described_class.pending).not_to include(sent_closed_high)
    end

    it 'provides pending status' do
      expect(pending_opened_normal).to be_pending
    end

    it 'provides sent status' do
      expect(sent_closed_high).to be_sent
    end

    it 'provides tour_opened kind' do
      expect(pending_opened_normal).to be_tour_opened
    end

    it 'provides tour_closed kind' do
      expect(sent_closed_high).to be_tour_closed
    end

    it 'provides normal priority' do
      expect(pending_opened_normal).to be_normal
    end

    it 'provides high priority' do
      expect(sent_closed_high).to be_high
    end
  end

  describe 'validations (implicit belongs_to)' do
    context 'without team' do
      let(:tour) { create(:tour) }

      it 'is invalid' do
        n = described_class.new(team: nil, notifiable: tour, kind: :tour_opened, status: :pending, priority: :normal)

        expect(n).not_to be_valid
      end
    end

    context 'without notifiable' do
      let(:team) { create(:team) }

      it 'is invalid' do
        n = described_class.new(team: team, notifiable: nil, kind: :tour_opened, status: :pending, priority: :normal)

        expect(n).not_to be_valid
      end
    end
  end
end
