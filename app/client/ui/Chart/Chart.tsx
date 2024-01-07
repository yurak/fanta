import { useEffect, useRef } from "react";
import {
  ChartData,
  ChartTypeRegistry,
  Chart as ChartJS,
  ChartType,
  DefaultDataPoint,
  registerables,
  PluginOptionsByType,
} from "chart.js";
import { _DeepPartialObject } from "chart.js/dist/types/utils";
import Skeleton from "react-loading-skeleton";
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
  plugins?: _DeepPartialObject<PluginOptionsByType<keyof ChartTypeRegistry>> | undefined,
}

const Chart = <
  TType extends ChartType = ChartType,
  TData = DefaultDataPoint<TType>,
  TLabel = unknown
>({
  data,
  type,
  plugins,
}: IChartProps<TType, TData, TLabel>) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const chart = useRef<ChartJS<keyof ChartTypeRegistry, TData, TLabel>>();

  useEffect(() => {
    if (!canvasRef.current) {
      return;
    }

    chart.current = new ChartJS(canvasRef.current, {
      type,
      data,
      options: {
        plugins,
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: { reverse: true, ticks: { precision: 0 } },
        },
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

  return <canvas className={styles.canvas} ref={canvasRef} />;
};

interface IChartContainerProps<
  TType extends ChartType = ChartType,
  TData = DefaultDataPoint<TType>,
  TLabel = unknown
> extends IChartProps<TType, TData, TLabel> {
  isLoading?: boolean,
  className?: string,
}

const ChartContainer = <
  TType extends ChartType = ChartType,
  TData = DefaultDataPoint<TType>,
  TLabel = unknown
>({
  className,
  isLoading,
  ...restProps
}: IChartContainerProps<TType, TData, TLabel>) => {
  return (
    <div className={className}>
      {isLoading ? (
        <Skeleton containerClassName={styles.skeletonContainer} className={styles.skeleton} />
      ) : (
        <Chart {...restProps} />
      )}
    </div>
  );
};

export default ChartContainer;
