import { PlayerPosition } from "@/interfaces/Player";

export const positionMappers: Record<
  PlayerPosition,
  {
    color: "yellow" | "green" | "blue" | "purple" | "red",
    label: string,
    fantaLabel: string,
  }
> = {
  // yellow
  [PlayerPosition.GK]: {
    color: "yellow",
    label: "GK",
    fantaLabel: "Por",
  },
  // green
  [PlayerPosition.CB]: {
    color: "green",
    label: "CB",
    fantaLabel: "Dc",
  },
  [PlayerPosition.LB]: {
    color: "green",
    label: "LB",
    fantaLabel: "Ds",
  },
  [PlayerPosition.RB]: {
    color: "green",
    label: "RB",
    fantaLabel: "Dd",
  },
  // blue
  [PlayerPosition.WB]: {
    color: "blue",
    label: "WB",
    fantaLabel: "E",
  },
  [PlayerPosition.DM]: {
    color: "blue",
    label: "DM",
    fantaLabel: "M",
  },
  [PlayerPosition.CM]: {
    color: "blue",
    label: "CM",
    fantaLabel: "C",
  },
  // purple
  [PlayerPosition.AM]: {
    color: "purple",
    label: "AM",
    fantaLabel: "T",
  },
  [PlayerPosition.W]: {
    color: "purple",
    label: "W",
    fantaLabel: "W",
  },
  // red
  [PlayerPosition.FW]: {
    color: "purple",
    label: "FW",
    fantaLabel: "A",
  },
  [PlayerPosition.ST]: {
    color: "purple",
    label: "ST",
    fantaLabel: "Pc",
  },
};
