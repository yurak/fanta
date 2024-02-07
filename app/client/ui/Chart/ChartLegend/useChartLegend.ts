import { useEffect, useMemo, useState } from "react";
import {
  ChartTypeRegistry,
  Chart as ChartJS,
  DefaultDataPoint,
  ChartType,
  ChartDataset,
} from "chart.js";
import { IProps as IChartLegendProps } from "./ChartLegend";

export const useChartLegend = <
  TType extends ChartType = ChartType,
  TData = DefaultDataPoint<TType>,
  TLabel = unknown
>(
  datasets: ChartDataset<TType, TData>[],
  chartInstance?: ChartJS<keyof ChartTypeRegistry, TData, TLabel>
) => {
  const [hiddenDatasets, setHiddenDatasets] = useState<number[]>([]);

  useEffect(() => {
    setHiddenDatasets([]);
  }, [datasets]);

  const onClick = (index: number) => {
    const isHidden = hiddenDatasets.includes(index);

    if (isHidden) {
      chartInstance?.show(index);
    } else {
      chartInstance?.hide(index);
    }

    setHiddenDatasets((hiddenDatasets) => {
      if (hiddenDatasets.includes(index)) {
        return hiddenDatasets.filter((dataset) => dataset !== index);
      }

      return [...hiddenDatasets, index];
    });
  };

  const legends = useMemo<IChartLegendProps["legends"]>(() => {
    return datasets.map((dataset, index) => ({
      index,
      isActive: !hiddenDatasets.includes(index),
      color: dataset.backgroundColor as string,
      label: dataset.label,
    }));
  }, [datasets, hiddenDatasets]);

  return {
    hiddenDatasets,
    onClick,
    legends,
  };
};
