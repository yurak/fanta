type SliderRangeValueType = number[];

export interface IFilter {
  position: string[],
  totalScore: SliderRangeValueType,
  baseScore: SliderRangeValueType,
  appearances: SliderRangeValueType,
  price: SliderRangeValueType,
}
