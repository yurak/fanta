module Api
  class AuctionsController < Api::ApplicationController
    include AuctionsHelper

    def index
      return not_found unless league

      render json: { data: { auctions: auctions.map { |auction| auction_entry(auction) } } }
    end

    private

    def league
      return @league if defined?(@league)

      @league = League.find_by(id: params[:league_id])
    end

    def auctions
      league.auctions.includes(:auction_rounds, :transfers).to_a.reverse
    end

    def auction_entry(auction)
      { hidden: upcoming?(auction), rows: rows(auction) }
    end

    def upcoming?(auction)
      !auction.primary? && auction.deadline.blank?
    end

    def rows(auction)
      rows = [main_row(auction)]
      rows << dropping_row(auction) if !auction.primary? && auction.deadline
      rows
    end

    def main_row(auction)
      status = auction_status(auction)

      base_row(auction).merge(
        href: auction_link(auction),
        icon: t("auction.index.icon.initial_#{auction.initial?}"),
        icon_active: auction.live? || auction.blind_bids?,
        title: auction.primary? ? t('auction.index.initial_title') : t('auction.index.intermediate_title', number: auction.number),
        transfers: transfers_text(auction, auction.transfers.incoming.count),
        transfers_status: status,
        status: status,
        status_text: t("auction.index.status.#{status}"),
        status_icon: status_icon(status),
        date: auction_dates(auction, current_user)
      )
    end

    def dropping_row(auction)
      status = auction_dropping_status(auction)

      base_row(auction).merge(
        href: dropping_link(auction),
        icon: t('auction.index.icon.dropping'),
        icon_active: auction.sales?,
        title: t('auction.index.dropping_title'),
        title_status: status,
        transfers: transfers_text(auction, auction.transfers.all_out.count),
        status: status,
        status_text: t("auction.index.status.#{status}"),
        status_icon: status_icon(status),
        date: dropping_date(auction)
      )
    end

    def base_row(auction)
      {
        item_status: auction.status,
        title_status: nil,
        transfers_status: nil,
        arrow_icon: helpers.image_path('icons/arrow_right_link.svg')
      }
    end

    def transfers_text(auction, count)
      auction.initial? || auction.sales? ? '-' : "🔄 #{count}"
    end

    def status_icon(status)
      helpers.image_path("icons/auctions/#{status}.svg")
    end

    def dropping_date(auction)
      return auction_local_time(auction.deadline, current_user) if auction.sales?

      "#{(auction.deadline - 5.days)&.strftime('%b %e')} - #{auction.deadline&.strftime('%b %e, %Y')}"
    end
  end
end
