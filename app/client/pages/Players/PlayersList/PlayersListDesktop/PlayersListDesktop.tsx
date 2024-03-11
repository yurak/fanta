import { IPlayer } from "@/interfaces/Player";
import Table from "@/ui/Table";
import TournamentsLoader from "@/components/loaders/TournamentsLoader";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import { formatNumber } from "@/helpers/formatNumber";
import { ITableSorting } from "@/ui/Table/interfaces";
import PlayersListInfo from "../PlayersListInfo";
import styles from "./PlayersListDesktop.module.scss";

const PlayersListDesktop = ({
  items,
  isLoading,
  sorting,
}: {
  items: IPlayer[],
  isLoading: boolean,
  sorting: ITableSorting,
}) => {
  return (
    <Table
      rounded
      dataSource={items}
      isLoading={isLoading}
      sorting={sorting}
      columns={[
        {
          dataKey: "name",
          title: "Name",
          dataClassName: styles.nameDataCell,
          className: styles.nameCell,
          sorter: true,
          supportAscSorting: true,
          render: (player) => <PlayersListInfo player={player} />,
        },
        {
          dataKey: "tournament",
          title: "TMNT",
          className: styles.tournamentCell,
          render: ({ club }) => {
            if (!club.tournament_id) {
              return "-";
            }

            return (
              <TournamentsLoader>
                {(tournaments) => {
                  const tournament = tournaments.find((t) => t.id === club.tournament_id);

                  if (!tournament) {
                    return "-";
                  }

                  return (
                    <div className={styles.logo}>
                      <img src={tournament.logo} alt={tournament.name} />
                    </div>
                  );
                }}
              </TournamentsLoader>
            );
          },
        },
        {
          dataKey: "club",
          title: "Club",
          className: styles.clubCell,
          render: ({ club }) => {
            return (
              <div className={styles.logo}>
                <img src={club.logo_path} alt={club.name} />
              </div>
            );
          },
        },
        {
          dataKey: "position",
          title: "Position",
          className: styles.positionsCell,
          sorter: true,
          supportAscSorting: true,
          render: ({ position_classic_arr }) => (
            <PlayerPositions positions={position_classic_arr} />
          ),
        },
        {
          dataKey: "average_price",
          title: "Price",
          align: "right",
          className: styles.priceCell,
          noWrap: true,
          sorter: true,
          supportAscSorting: true,
          render: ({ average_price }) => {
            return formatNumber(average_price, {
              zeroFallback: "-",
              minimumFractionDigits: 1,
              maximumFractionDigits: 1,
              suffix: "M",
            });
          },
        },
        {
          dataKey: "teams_count",
          title: (
            <>
              <span className={styles.desktopTitle}># of teams</span>
              <span className={styles.mobileTitle}>Teams</span>
            </>
          ),
          align: "right",
          noWrap: true,
          className: styles.totalTeamsCell,
          render: ({ teams_count }) => {
            if (teams_count === 0) {
              return 0;
            }

            return (
              <>
                {formatNumber(teams_count)} <span className={styles.totalTeamCount}>(n/a)</span>
              </>
            );
          },
        },
        {
          dataKey: "appearances",
          title: "Apps",
          align: "right",
          noWrap: true,
          className: styles.appsCell,
          sorter: true,
          supportAscSorting: true,
          render: ({ appearances }) => {
            if (appearances === 0) {
              return 0;
            }

            return (
              <>
                {formatNumber(appearances)} <span className={styles.totalApps}>(n/a)</span>
              </>
            );
          },
        },
        {
          dataKey: "base_score",
          align: "right",
          title: "BS",
          className: styles.baseScoreCell,
          sorter: true,
          supportAscSorting: true,
          noWrap: true,
          render: ({ average_base_score }) => {
            return formatNumber(Number(average_base_score), {
              minimumFractionDigits: 2,
              maximumFractionDigits: 2,
            });
          },
        },
        {
          dataKey: "total_score",
          title: "TS",
          align: "right",
          dataClassName: styles.totalScoreDataCell,
          className: styles.totalScoreCell,
          sorter: true,
          supportAscSorting: true,
          noWrap: true,
          render: ({ average_total_score }) => {
            return formatNumber(Number(average_total_score), {
              minimumFractionDigits: 2,
              maximumFractionDigits: 2,
            });
          },
        },
      ]}
    />
  );
};

export default PlayersListDesktop;
