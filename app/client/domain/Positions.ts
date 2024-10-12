import { Position } from "@/interfaces/Position";

const positionMappers: Record<
  Position,
  {
    color: "yellow" | "green" | "blue" | "purple" | "red",
    label: string,
    fantaLabel: string,
    fullName: string,
  }
> = {
  [Position.GK]: {
    color: "yellow",
    label: "GK",
    fantaLabel: "Por",
    fullName: "Goalkeeper",
  },
  [Position.CB]: {
    color: "green",
    label: "CB",
    fantaLabel: "Dc",
    fullName: "Centre back",
  },
  [Position.LB]: {
    color: "green",
    label: "LB",
    fantaLabel: "Ds",
    fullName: "Left back",
  },
  [Position.RB]: {
    color: "green",
    label: "RB",
    fantaLabel: "Dd",
    fullName: "Right back",
  },
  [Position.WB]: {
    color: "blue",
    label: "WB",
    fantaLabel: "E",
    fullName: "Wing back",
  },
  [Position.DM]: {
    color: "blue",
    label: "DM",
    fantaLabel: "M",
    fullName: "Defensive midfielder",
  },
  [Position.CM]: {
    color: "blue",
    label: "CM",
    fantaLabel: "C",
    fullName: "Centre midfielder",
  },
  [Position.AM]: {
    color: "purple",
    label: "AM",
    fantaLabel: "T",
    fullName: "Winger",
  },
  [Position.W]: {
    color: "purple",
    label: "W",
    fantaLabel: "W",
    fullName: "Attacking midfielder",
  },
  [Position.FW]: {
    color: "red",
    label: "FW",
    fantaLabel: "A",
    fullName: "Forward",
  },
  [Position.ST]: {
    color: "red",
    label: "ST",
    fantaLabel: "Pc",
    fullName: "Striker",
  },
};

export class Positions {
  static getFullNameById(id: Position) {
    return positionMappers[id].fullName;
  }

  static getLabelById(id: Position, italPosition?: boolean) {
    const position = positionMappers[id];

    return italPosition ? position.fantaLabel : position.label;
  }

  static getColorById(id: Position) {
    return positionMappers[id].color;
  }
}
