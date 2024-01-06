import { useMemo } from "react";
import { ChartData } from "chart.js";
import Chart, { DEFAULT_COLORS } from "../../../../../ui/Chart";
import { ILeagueResults } from "../../../../../interfaces/LeagueResults";
import styles from "./LeagueResultsMantraChart.module.scss";

type ChartDataType = ChartData<"line", (number | null)[], React.ReactNode>;

const LeagueResultsMantraChart = ({
  leaguesResults,
  isLoading,
}: {
  leaguesResults: ILeagueResults[];
  isLoading: boolean;
}) => {
  const historyItems = leaguesResults[0]?.history.length ?? 0;

  const labels = useMemo<ChartDataType["labels"]>(
    () => Array.from({ length: historyItems - 1 }).map((_, index) => index + 1),
    [historyItems]
  );

  const datasets = useMemo<ChartDataType["datasets"]>(() => {
    return [...leaguesResults]
      .sort((teamA, teamB) => teamA.team.id - teamB.team.id)
      .map((teamResult, index): ChartDataType["datasets"][0] => {
        const [_, ...history] = teamResult.history;

        return {
          label: teamResult.team?.human_name ?? teamResult.id.toString(),
          data: history.map((teamFormItem) => teamFormItem?.pos ?? null),
          backgroundColor: DEFAULT_COLORS[index],
          borderColor: DEFAULT_COLORS[index],
        };
      });
  }, [leaguesResults]);

  const chartData = useMemo<ChartDataType>(
    () => ({
      labels,
      datasets,
    }),
    [datasets, labels]
  );

  return (
    <Chart
      type="line"
      isLoading={isLoading}
      data={chartData}
      className={styles.canvas}
      plugins={{
        tooltip: {
          itemSort: (a, b) => Number(a.formattedValue) - Number(b.formattedValue),
        },
      }}
    />
  );
};

export default LeagueResultsMantraChart;
