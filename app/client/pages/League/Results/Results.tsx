import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import Link from "@/ui/Link";
import { useLeague } from "@/api/query/useLeague";
import Heading from "@/components/Heading";
import PageLayout from "@/layouts/PageLayout";
import ResultsMantra from "./ResultsMantra";
import ResultsFanta from "./ResultsFanta";
import ResultsSkeleton from "./ResultsSkeleton";
import styles from "./Results.module.scss";

const ResultsPage = () => {
  const params = useParams<{ leagueId: string }>();
  const leagueId = Number(params.leagueId);
  const league = useLeague(leagueId);
  const { t } = useTranslation();

  return (
    <PageLayout withSidebar>
      <div className={styles.heading}>
        <Heading title={t("table.title")} noSpace />
        {league.data?.mantra_format && league.data?.division && (
          <Link to={`/tournaments/${league.data?.tournament_id}/divisions`}>
            {t("table.division")} {league.data?.division}
          </Link>
        )}
      </div>
      {league.data ? (
        <>
          {league.data.mantra_format ? (
            <ResultsMantra leagueData={league.data} leagueId={leagueId} />
          ) : (
            <ResultsFanta leagueId={leagueId} />
          )}
        </>
      ) : (
        <ResultsSkeleton />
      )}
    </PageLayout>
  );
};

export default ResultsPage;
