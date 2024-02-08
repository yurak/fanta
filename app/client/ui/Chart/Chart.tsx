import { useEffect, useRef, useState } from "react";
import cn from "classnames";
import {
  ChartData,
  ChartTypeRegistry,
  Chart as ChartJS,
  ChartType,
  DefaultDataPoint,
  registerables,
  PluginOptionsByType,
  ScaleOptionsByType,
} from "chart.js";
import { DeepPartial } from "chart.js/dist/types/utils";
import Skeleton from "react-loading-skeleton";
import ChartLegend, { useChartLegend } from "./ChartLegend";
import ChartTooltip, { ITooltip } from "./ChartTooltip";
import styles from "./Сhart.module.scss";

ChartJS.register(...registerables);

export const DEFAULT_COLORS = [
  "#007bff",
  "#fd7e14",
  "#28a745",
  "#6c757d",
  "#ffc107",
  "#dc3545",
  "#6f42c1",
  "#20c997",
  "#e83e8c",
  "#17a2b8",
  "#6610f2",
];

interface IChartProps<
  TType extends ChartType = ChartType,
  TData = DefaultDataPoint<TType>,
  TLabel = unknown
> {
  data: ChartData<TType, TData, TLabel>,
  type: ChartType,
  plugins?: DeepPartial<PluginOptionsByType<keyof ChartTypeRegistry>> | undefined,
  scales?: DeepPartial<{
    [key: string]: ScaleOptionsByType<ChartTypeRegistry[TType]["scales"]>,
  }>,
  className?: string,
  canvasClassName?: string,
}

const Chart = <
  TType extends ChartType = ChartType,
  TData = DefaultDataPoint<TType>,
  TLabel = unknown
>({
  data,
  type,
  plugins,
  scales,
  className,
  canvasClassName,
}: IChartProps<TType, TData, TLabel>) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const chart = useRef<ChartJS<keyof ChartTypeRegistry, TData, TLabel>>();
  const legend = useChartLegend(data.datasets, chart.current);
  const [tooltip, setTooltip] = useState<ITooltip<TType> | null>(null);

  useEffect(() => {
    if (!canvasRef.current) {
      return;
    }

    chart.current = new ChartJS<keyof ChartTypeRegistry, TData, TLabel>(canvasRef.current, {
      type,
      data,
      options: {
        plugins: {
          ...(plugins ?? {}),
          legend: {
            display: false,
          },
          tooltip: {
            enabled: false,
            external: ({ chart, tooltip }) => {
              if (!tooltip.opacity) {
                setTooltip(null);

                return;
              }

              let dataPoints = tooltip.dataPoints;

              if (typeof plugins?.tooltip?.itemSort === "function") {
                dataPoints = dataPoints.sort((a, b) =>
                  plugins.tooltip!.itemSort!(a, b, chart.data)
                );
              }

              setTooltip({
                leftAlign: tooltip.xAlign === "left",
                offset:
                  tooltip.xAlign === "left" ? tooltip.x : chart.width - tooltip.x - tooltip.width,
                bottom: chart.height - chart.chartArea.bottom,
                title: tooltip.title,
                dataPoints,
              });
            },
          },
        },
        responsive: true,
        maintainAspectRatio: false,
        scales,
        transitions: {
          show: { animations: { x: { from: 0 }, y: { from: 0 } } },
          hide: { animations: { x: { to: 0 }, y: { to: 0 } } },
        },
        interaction: {
          intersect: false,
          mode: "index",
        },
      },
    });

    return () => {
      chart.current?.destroy();
    };
  }, [data]);

  return (
    <>
      <div className={styles.legend}>
        <ChartLegend {...legend} />
      </div>
      <div className={cn(styles.chart, className)}>
        <div className={cn(styles.canvasWrapper, canvasClassName)}>
          <ChartTooltip tooltip={tooltip} />
          <canvas className={styles.canvas} ref={canvasRef} />
        </div>
      </div>
    </>
  );
};

interface IChartContainerProps<
  TType extends ChartType = ChartType,
  TData = DefaultDataPoint<TType>,
  TLabel = unknown
> extends IChartProps<TType, TData, TLabel> {
  isLoading?: boolean,
}

const ChartContainer = <
  TType extends ChartType = ChartType,
  TData = DefaultDataPoint<TType>,
  TLabel = unknown
>({
  isLoading,
  ...restProps
}: IChartContainerProps<TType, TData, TLabel>) => {
  return (
    <div>
      {isLoading ? (
        <>
          <div className={styles.legend}>
            <Skeleton inline containerClassName={styles.skeletonLegend} count={4} />
          </div>
          <div className={restProps.className}>
            <Skeleton containerClassName={styles.chartSkeleton} className={styles.chartSkeleton} />
          </div>
        </>
      ) : (
        <Chart {...restProps} />
      )}
    </div>
  );
};

export default ChartContainer;
