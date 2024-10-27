import Skeleton from "react-loading-skeleton";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import PlayersPageConfigurationContextProvider from "@/application/Players/PlayersPageConfigurationContext";
import PlayersPage from "@/components/PlayersPage";
import PageLayout from "@/layouts/PageLayout";
import Link from "@/ui/Link";
import { useLeague } from "@/api/query/useLeague";
import UserCircleIcon from "@/assets/icons/userCircle.svg";
import styles from "./LeaguePlayers.module.scss";
import { ILeague } from "@/interfaces/League";

const LeaguePlayersTitle = ({ league, isFetching }: { league?: ILeague, isFetching: boolean }) => {
  const { t } = useTranslation();

  return (
    <>
      <span className={styles.desktop}>
        {isFetching || !league ? (
          <Skeleton containerClassName={styles.skeleton} />
        ) : (
          `${league.name} players`
        )}
      </span>
      <span className={styles.mobile}>{t("players.players")}</span>
    </>
  );
};

const LeaguePlayers = () => {
  const params = useParams<{ leagueId: string }>();
  const leagueId = Number(params.leagueId);

  const { data: league, isLoading, isPending } = useLeague(leagueId);

  return (
    <PlayersPageConfigurationContextProvider isLeagueSpecificPlayersPage leagueId={leagueId}>
      <PageLayout withSidebar>
        <PlayersPage
          title={<LeaguePlayersTitle league={league} isFetching={isLoading || isPending} />}
          actions={
            <Link to="/players" icon={<UserCircleIcon />}>
              <span className={styles.mobile}>All Players</span>
              <span className={styles.desktop}>All Mantra Players</span>
            </Link>
          }
        />
      </PageLayout>
    </PlayersPageConfigurationContextProvider>
  );
};

export default LeaguePlayers;
