import { useLeague } from "../../../api/query/useLeague";
import { withBootstrap } from "../../../bootstrap/withBootstrap";
import PageHeading from "../../../components/PageHeading";
import PageLayout from "../../../layouts/PageLayout";
import LeaguesResultsTable from "./LeaguesResultsTable";
import LeagueResultsChart from "./LeagueResultsChart";
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
        <PageHeading title="Table" />
      </div>
      {league.data ? (
        <>
          {league.data.mantra_format ? (
            <>
              <LeaguesResultsTable
                promotion={league.data.promotion}
                relegation={league.data.relegation}
                teamsCount={league.data.teams_count}
                leagueId={leagueId}
              />
              <LeagueResultsChart leagueId={leagueId} teamsCount={league.data.teams_count} />
            </>
          ) : (
            <>TODO: Fanta table</>
          )}
        </>
      ) : (
        "League loading..."
      )}
    </PageLayout>
  );
};

export default withBootstrap(LeagueResultsPage);
