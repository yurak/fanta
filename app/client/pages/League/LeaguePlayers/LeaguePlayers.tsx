import Skeleton from "react-loading-skeleton";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import PlayersPage from "@/components/PlayersPage";
import PageLayout from "@/layouts/PageLayout";
import Link from "@/ui/Link";
import { useLeague } from "@/api/query/useLeague";
import UserCircleIcon from "@/assets/icons/userCircle.svg";
import styles from "./LeaguePlayers.module.scss";

const LeaguePlayersTitle = ({ leagueId }: { leagueId: number }) => {
  const { t } = useTranslation();
  const { data: league, isLoading, isPending } = useLeague(leagueId);

  return (
    <>
      <span className={styles.desktop}>
        {isLoading || isPending || !league ? (
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

  return (
    <PageLayout withSidebar>
      <PlayersPage
        title={<LeaguePlayersTitle leagueId={leagueId} />}
        actions={
          <Link to="/players" icon={<UserCircleIcon />}>
            <span className={styles.mobile}>All Players</span>
            <span className={styles.desktop}>All Mantra Players</span>
          </Link>
        }
      />
    </PageLayout>
  );
};

export default LeaguePlayers;
