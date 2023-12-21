import { useEffect, useRef } from "react";
import { ChartData, Chart as ChartJS, ChartType, DefaultDataPoint, registerables } from "chart.js";

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

const Chart = <
  TType extends ChartType = ChartType,
  TData = DefaultDataPoint<TType>,
  TLabel = unknown
>({
  data,
  type,
}: {
  data: ChartData<TType, TData, TLabel>;
  type: ChartType;
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    if (!canvasRef.current) {
      return;
    }

    const chartJs = new ChartJS(canvasRef.current, {
      type,
      data,
      options: {
        responsive: true,
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
      chartJs.destroy();
    };
  }, []);

  return <canvas ref={canvasRef} />;
};

export default Chart;
