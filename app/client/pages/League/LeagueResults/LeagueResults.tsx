import { useLeague } from "../../../api/query/useLeague";
import { withBootstrap } from "../../../bootstrap/withBootstrap";
import PageHeading from "../../../components/Heading";
import PageLayout from "../../../layouts/PageLayout";
import LeagueResultsMantra from "./LeagueResultsMantra";
import LeagueResultsFanta from "./LeagueResultsFanta";
import ArrowRight from "../../../assets/icons/arrow-right.svg";
import styles from "./LeagueResults.module.scss";

const getLeagueId = () => {
  if (typeof window !== "object") {
    return null;
  }

  const id = window.location.pathname.split("/")[2];

  return Number(id);
};

const LeagueResultsPage = () => {
  const leagueId = getLeagueId() as number;
  const league = useLeague(leagueId);

  return (
    <PageLayout withSidebar>
      <div className={styles.heading}>
        <PageHeading title="Table" noSpace />
        {league.data && (
          <a
            className={styles.divisionsLink}
            href={`/tournaments/${league.data?.division_id}/divisions`}
          >
            📊 Divisions
            <ArrowRight className={styles.divisionsLinkIcon} />
          </a>
        )}
      </div>
      {league.data ? (
        <>
          {league.data.mantra_format ? (
            <LeagueResultsMantra leagueData={league.data} leagueId={leagueId} />
          ) : (
            <LeagueResultsFanta leagueData={league.data} leagueId={leagueId} />
          )}
        </>
      ) : (
        "League loading..."
      )}
    </PageLayout>
  );
};

export default withBootstrap(LeagueResultsPage);
