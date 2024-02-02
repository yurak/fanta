import { useTranslation } from "react-i18next";
import { useMemo } from "react";
import { useLeagueResults } from "../../../../api/query/useLeagueResults";
import { ILeagueFullData } from "../../../../interfaces/League";
import { ILeagueResults } from "../../../../interfaces/LeagueResults";
import PageHeading from "../../../../components/Heading";
import ChartIndicator from "../../../../assets/images/chartIndicator.svg";
import ResultsMantraChart from "./ResultsMantraChart";
import ResultsMantraTable from "./ResultsMantraTable";
import styles from "./ResultsMantra.module.scss";

const ResultsMantra = ({
  leagueData,
  leagueId,
}: {
  leagueData: ILeagueFullData,
  leagueId: number,
}) => {
  const leaguesResults = useLeagueResults<ILeagueResults>(leagueId);

  const isThereSomeChartData = useMemo(
    () => leaguesResults.data.some((item) => item.history.some(Boolean)),
    [leaguesResults.data]
  );

  const { t } = useTranslation();

  return (
    <>
      <ResultsMantraTable
        promotion={leagueData.promotion}
        relegation={leagueData.relegation}
        teamsCount={leagueData.teams_count}
        leaguesResults={leaguesResults.data}
        isLoading={leaguesResults.isLoading}
        isActiveLeague={leagueData.status === "active"}
      />
      {(leaguesResults.isLoading || isThereSomeChartData) && (
        <div className={styles.chart}>
          <PageHeading tag="h4" title={t("table.trend_title")} titleIcon={<ChartIndicator />} />
          <ResultsMantraChart
            leaguesResults={leaguesResults.data}
            isLoading={leaguesResults.isLoading}
          />
        </div>
      )}
    </>
  );
};

export default ResultsMantra;
