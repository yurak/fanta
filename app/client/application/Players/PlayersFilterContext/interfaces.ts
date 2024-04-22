import { Position } from "@/interfaces/Position";
import { RangeSliderValueType } from "@/ui/RangeSlider";

export interface IFilter {
  clubs: number[],
  position: Position[],
  totalScore: RangeSliderValueType,
  baseScore: RangeSliderValueType,
  appearances: RangeSliderValueType,
  price: RangeSliderValueType,
  teamsCount: RangeSliderValueType,
}
