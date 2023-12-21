import { useMemo } from "react";
import { ChartData } from "chart.js";
import Chart, { DEFAULT_COLORS } from "../../../../ui/Chart";
import { useLeagueResults } from "../../../../api/query/useLeagueResults";
import { useTeams } from "../../../../api/query/useTeam";
import { ITeam } from "../../../../interfaces/Team";
import { ILeagueResults } from "../../../../interfaces/LeagueResults";

type ChartDataType = ChartData<"line", number[], React.ReactNode>;
type LeagueResultWithTeam = ILeagueResults & { team?: ITeam };

const LeagueResultsChartWrapper = ({
  leagueId,
  teamsCount,
}: {
  leagueId: number;
  teamsCount: number;
}) => {
  const leaguesResults = useLeagueResults(leagueId);
  const teamsIds = leaguesResults.data.map(({ team_id }) => team_id);
  const teamsQuery = useTeams(teamsIds);

  const data = useMemo<LeagueResultWithTeam[]>(
    () =>
      leaguesResults.data.map((teamResult, index) => ({
        ...teamResult,
        team: teamsQuery[index]?.data,
      })),
    []
  );

  if (teamsQuery.some((teamQuery) => teamQuery.isLoading) || leaguesResults.isLoading) {
    return "Loading...";
  }

  return <LeagueResultsChart teamsCount={teamsCount} data={data} />;
};

const LeagueResultsChart = ({
  teamsCount,
  data,
}: {
  teamsCount: number;
  data: LeagueResultWithTeam[];
}) => {
  const labels = useMemo<ChartDataType["labels"]>(
    () => Array.from({ length: teamsCount }).map((_, index) => index + 1),
    [teamsCount]
  );

  const datasets = useMemo<ChartDataType["datasets"]>(() => {
    return [...data]
      .sort((teamA, teamB) => teamA.team_id - teamB.team_id)
      .map((teamResult, index): ChartDataType["datasets"][0] => ({
        label: teamResult.team?.human_name ?? teamResult.id.toString(),
        data: teamResult.history.map((teamFormItem) => teamFormItem?.pos ?? 0).filter(Boolean),
        backgroundColor: DEFAULT_COLORS[index],
        borderColor: DEFAULT_COLORS[index],
      }));
  }, [data]);

  const chartData = useMemo<ChartDataType>(
    () => ({
      labels,
      datasets,
    }),
    [labels]
  );

  return <Chart type="line" data={chartData} />;
};

export default LeagueResultsChartWrapper;
