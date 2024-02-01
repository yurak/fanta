import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { useLeague } from "../../../api/query/useLeague";
import PageHeading from "../../../components/Heading";
import PageLayout from "../../../layouts/PageLayout";
import LeagueResultsMantra from "./LeagueResultsMantra";
import LeagueResultsFanta from "./LeagueResultsFanta";
import LeagueResultsSkeleton from "./LeagueResultsSkeleton";
import ArrowRight from "../../../assets/icons/arrow-right.svg";
import styles from "./LeagueResults.module.scss";

const LeagueResultsPage = () => {
  const params = useParams<{ leagueId: string }>();
  const leagueId = Number(params.leagueId);
  const league = useLeague(leagueId);
  const { t } = useTranslation();

  return (
    <PageLayout withSidebar>
      <div className={styles.heading}>
        <PageHeading title={t("table.title")} noSpace />
        {league.data?.mantra_format && (
          <a
            className={styles.divisionsLink}
            href={`/tournaments/${league.data?.tournament_id}/divisions`}
          >
            📊 {t("divisions.title")}
            <ArrowRight className={styles.divisionsLinkIcon} />
          </a>
        )}
      </div>
      {league.data ? (
        <>
          {league.data.mantra_format ? (
            <LeagueResultsMantra leagueData={league.data} leagueId={leagueId} />
          ) : (
            <LeagueResultsFanta leagueId={leagueId} />
          )}
        </>
      ) : (
        <LeagueResultsSkeleton />
      )}
    </PageLayout>
  );
};

export default LeagueResultsPage;
