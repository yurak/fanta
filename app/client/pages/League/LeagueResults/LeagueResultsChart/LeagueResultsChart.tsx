import { useMemo } from "react";
import { ChartData } from "chart.js";
import Chart, { DEFAULT_COLORS } from "../../../../ui/Chart";
import { useLeagueResults } from "../../../../api/query/useLeagueResults";

type ChartDataType = ChartData<"line", number[], React.ReactNode>;

const LeagueResultsChart = ({ leagueId, teamsCount }: { leagueId: number; teamsCount: number }) => {
  const leaguesResults = useLeagueResults(leagueId);

  const labels = useMemo<ChartDataType["labels"]>(
    () => Array.from({ length: teamsCount }).map((_, index) => index + 1),
    [teamsCount]
  );

  const datasets = useMemo<ChartDataType["datasets"]>(() => {
    return [...leaguesResults.data]
      .sort((teamA, teamB) => teamA.team.id - teamB.team.id)
      .map((teamResult, index): ChartDataType["datasets"][0] => ({
        label: teamResult.team?.human_name ?? teamResult.id.toString(),
        data: teamResult.history.map((teamFormItem) => teamFormItem?.pos ?? 0).filter(Boolean),
        backgroundColor: DEFAULT_COLORS[index],
        borderColor: DEFAULT_COLORS[index],
      }));
  }, [leaguesResults.data]);

  const chartData = useMemo<ChartDataType>(
    () => ({
      labels,
      datasets,
    }),
    [labels]
  );

  return <Chart type="line" data={chartData} />;
};

export default LeagueResultsChart;
