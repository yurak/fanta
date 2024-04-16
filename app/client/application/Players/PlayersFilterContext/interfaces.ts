import { RangeSliderValueType } from "@/ui/RangeSlider";

export interface IFilter {
  clubs: number[],
  position: string[],
  totalScore: RangeSliderValueType,
  baseScore: RangeSliderValueType,
  appearances: RangeSliderValueType,
  price: RangeSliderValueType,
  teamsCount: RangeSliderValueType,
}
