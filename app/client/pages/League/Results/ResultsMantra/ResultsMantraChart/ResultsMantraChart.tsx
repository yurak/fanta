import { useMemo, useState } from "react";
import { ChartData } from "chart.js";
import { useTranslation } from "react-i18next";
import { sorters } from "../../../../../helpers/sorters";
import Chart, { DEFAULT_COLORS } from "../../../../../ui/Chart";
import { ILeagueResults } from "../../../../../interfaces/LeagueResults";
import Heading from "../../../../../components/Heading";
import ChartIndicator from "../../../../../assets/images/chartIndicator.svg";
import Select from "../../../../../ui/Select";
import styles from "./ResultsMantraChart.module.scss";

type ChartDataType = ChartData<"line", (number | null)[], React.ReactNode>;

interface ISourceOption {
  label: string,
  key: string,
}

const dataSourceOptions: ISourceOption[] = [
  { label: "Position", key: "pos" },
  { label: "Points", key: "p" },
];

const LeagueResultsMantraChart = ({
  leaguesResults,
  isLoading,
}: {
  leaguesResults: ILeagueResults[],
  isLoading: boolean,
}) => {
  const [source, setSource] = useState<ISourceOption>(dataSourceOptions[0] as ISourceOption);
  const { t } = useTranslation();

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
          data: history.map((teamFormItem) => teamFormItem?.[source.key] ?? null),
          backgroundColor: DEFAULT_COLORS[index],
          borderColor: DEFAULT_COLORS[index],
        };
      });
  }, [leaguesResults, source]);

  const chartData = useMemo<ChartDataType>(
    () => ({
      labels,
      datasets,
    }),
    [datasets, labels]
  );

  const isReverse = source.key === "pos";

  return (
    <div
      style={
        {
          "--item-count": historyItems,
        } as React.CSSProperties
      }
    >
      <div className={styles.heading}>
        <Heading tag="h4" title={t("table.trend_title")} titleIcon={<ChartIndicator />} noSpace />
        <Select
          options={dataSourceOptions}
          onChange={(value) => setSource(value as ISourceOption)}
          value={source}
          getOptionValue={(option) => option.key}
        />
      </div>
      <Chart
        type="line"
        isLoading={isLoading}
        data={chartData}
        className={styles.chart}
        canvasClassName={styles.canvas}
        plugins={{
          tooltip: {
            itemSort: sorters.numbers("formattedValue", true, isReverse),
          },
        }}
        scales={{
          y: { reverse: isReverse, ticks: { precision: 0 } },
          x: { ticks: { maxRotation: 0, autoSkipPadding: 20 } },
        }}
      />
    </div>
  );
};

export default LeagueResultsMantraChart;
