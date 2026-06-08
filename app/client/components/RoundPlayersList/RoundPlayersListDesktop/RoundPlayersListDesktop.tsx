import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import { IRoundPlayer } from "@/interfaces/RoundPlayer";
import Table, { IColumn } from "@/ui/Table";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import { formatNumber } from "@/helpers/formatNumber";
import { useRoundPlayersContext } from "@/application/RoundPlayers/RoundPlayersContext";
import { useRoundPlayersListContext } from "@/application/RoundPlayers/RoundPlayersListContext";
import { useRoundPlayersPageConfigurationContext } from "@/application/RoundPlayers/RoundPlayersPageConfigurationContext";
import RoundPlayersListInfo, { RoundPlayersListInfoSkeleton } from "../RoundPlayersListInfo";
import styles from "@/components/PlayersList/PlayersListDesktop/PlayersListDesktop.module.scss";

const scoreFormat = { minimumFractionDigits: 2, maximumFractionDigits: 2 };

const RoundPlayersListDesktop = ({
  emptyStateComponent,
}: {
  emptyStateComponent: React.ReactNode,
}) => {
  const { t } = useTranslation();
  const { sorting } = useRoundPlayersContext();
  const { items, isLoading, hasNextPage, loadMore } = useRoundPlayersListContext();
  const { national, fanta } = useRoundPlayersPageConfigurationContext();

  const columns = useMemo<IColumn<IRoundPlayer>[]>(() => {
    const cols: IColumn<IRoundPlayer>[] = [
      {
        dataKey: "name",
        title: t("round_players_page.columns.player"),
        dataClassName: styles.nameDataCell,
        className: styles.nameCell,
        sorter: true,
        supportAscSorting: true,
        render: (player) => <RoundPlayersListInfo player={player} />,
        skeleton: <RoundPlayersListInfoSkeleton />,
      },
      {
        dataKey: "position",
        title: t("round_players_page.columns.positions"),
        className: styles.positionsCell,
        render: ({ position_classic_arr }) => <PlayerPositions position={position_classic_arr} />,
      },
    ];

    if (fanta) {
      cols.push(
        {
          dataKey: "appearances",
          title: t("round_players_page.columns.appearances"),
          align: "right",
          noWrap: true,
          headEllipsis: true,
          className: styles.appsCell,
          sorter: true,
          supportAscSorting: true,
          render: ({ appearances }) => (appearances === null ? "-" : formatNumber(appearances)),
        },
        {
          dataKey: "main_appearances",
          title: t("round_players_page.columns.main_squad"),
          align: "right",
          noWrap: true,
          headEllipsis: true,
          className: styles.appsCell,
          sorter: true,
          supportAscSorting: true,
          render: ({ main_appearances }) =>
            main_appearances === null ? "-" : formatNumber(main_appearances),
        }
      );
    }

    cols.push(
      {
        dataKey: "base_score",
        title: t("round_players_page.columns.base_score"),
        align: "right",
        className: styles.baseScoreCell,
        sorter: true,
        supportAscSorting: true,
        noWrap: true,
        render: ({ base_score }) => formatNumber(Number(base_score), scoreFormat),
      },
      {
        dataKey: "result_score",
        title: t("round_players_page.columns.total_score"),
        align: "right",
        dataClassName: styles.totalScoreDataCell,
        className: styles.totalScoreCell,
        sorter: true,
        supportAscSorting: true,
        noWrap: true,
        render: ({ result_score }) => formatNumber(Number(result_score), scoreFormat),
      },
      {
        dataKey: "club",
        title: t("round_players_page.columns.club"),
        className: styles.clubCell,
        render: ({ club }) => (
          <div className={styles.logo}>
            <img src={club.logo_path} alt={club.name} />
          </div>
        ),
      }
    );

    if (national) {
      cols.push({
        dataKey: "national",
        title: t("round_players_page.columns.national"),
        className: styles.clubCell,
        headEllipsis: true,
        render: ({ nationality }) =>
          nationality ? <span className={`flag-icon flag-icon-${nationality.toLowerCase()}`} /> : "-",
      });
    }

    return cols;
  }, [t, fanta, national]);

  return (
    <Table
      rounded
      dataSource={items}
      isLoading={isLoading}
      isLoadingMore={hasNextPage}
      onLoadMore={loadMore}
      sorting={sorting}
      emptyStateComponent={emptyStateComponent}
      skeletonItems={25}
      rowLink={(item) => `/players/${item.player_id}`}
      columns={columns}
    />
  );
};

export default RoundPlayersListDesktop;
