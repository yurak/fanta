import { useMemo } from "react";
import { ChartData } from "chart.js";
import Chart, { DEFAULT_COLORS } from "../../../../../ui/Chart";
import { ILeagueResults } from "../../../../../interfaces/LeagueResults";
import styles from "./LeagueResultsMantraChart.module.scss";

type ChartDataType = ChartData<"line", number[], React.ReactNode>;

const LeagueResultsMantraChart = ({
  teamsCount,
  leaguesResults,
  isLoading,
}: {
  teamsCount: number;
  leaguesResults: ILeagueResults[];
  isLoading: boolean;
}) => {
  console.log({ isLoading });

  const labels = useMemo<ChartDataType["labels"]>(
    () => Array.from({ length: teamsCount }).map((_, index) => index + 1),
    [teamsCount]
  );

  const datasets = useMemo<ChartDataType["datasets"]>(() => {
    return [...leaguesResults]
      .sort((teamA, teamB) => teamA.team.id - teamB.team.id)
      .map((teamResult, index): ChartDataType["datasets"][0] => ({
        label: teamResult.team?.human_name ?? teamResult.id.toString(),
        data: teamResult.history.map((teamFormItem) => teamFormItem?.pos ?? 0).filter(Boolean),
        backgroundColor: DEFAULT_COLORS[index],
        borderColor: DEFAULT_COLORS[index],
      }));
  }, [leaguesResults]);

  const chartData = useMemo<ChartDataType>(
    () => ({
      labels,
      datasets,
    }),
    [datasets, labels]
  );

  return (
    <div className={styles.chart}>
      <Chart type="line" data={chartData} />
    </div>
  );
};

export default LeagueResultsMantraChart;
