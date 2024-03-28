import { RangeSliderValueType } from "@/ui/RangeSlider";

export interface IFilter {
  position: string[],
  totalScore: RangeSliderValueType,
  baseScore: RangeSliderValueType,
  appearances: RangeSliderValueType,
  price: RangeSliderValueType,
}
