import { useState } from "react";
import { useTranslation } from "react-i18next";
import Chart from "@/ui/Chart";
import Tabs from "@/ui/Tabs";
import Select from "@/ui/Select";
import { IRoundStat, ISeasonTotal } from "@/interfaces/PlayerStats";
import BonusCell from "./BonusCell";
import { COMMON_COLUMNS, GK_COLUMNS, IBonusColumn, OUTFIELD_COLUMNS } from "./columns";
import DefaultLogo from "@/assets/icons/noTeam.svg";
import styles from "./PlayerPage.module.scss";

type TabId = "domestic" | "eurocups" | "international";

interface IPerfData {
  rounds: IRoundStat[],
  total: ISeasonTotal,
}

interface ISeasonOption {
  id: number,
  label: string,
}

const Header = ({ columns }: { columns: IBonusColumn[] }) => {
  const { t } = useTranslation();

  return (
    <div className={`${styles.perfRow} ${styles.perfHeaders}`}>
      <div className={styles.headerCell}>#</div>
      {columns.map((col) => (
        <div key={col.key} className={styles.headerCell} title={t(`players.${col.title}`)}>
          {t(`players.${col.header}`)}
        </div>
      ))}
      <div className={styles.headerCell} title={t("players.played_minutes")}>{t("players.pm")}</div>
      <div className={styles.headerCell} title={t("players.base_score")}>{t("players.bs")}</div>
      <div className={styles.headerCell} title={t("players.total_score")}>{t("players.ts")}</div>
      <div className={styles.headerCell} title={t("players.round_club")}>{t("players.round_c")}</div>
    </div>
  );
};

const RoundRow = ({
  round,
  columns,
  flagCode,
}: {
  round: IRoundStat,
  columns: IBonusColumn[],
  flagCode?: string | null,
}) => {
  return (
    <div
      className={`${styles.perfRow} ${styles.dataRow} ${
        Number(round.base_score) > 0 ? "" : styles.squadOnlyRow
      }`}
    >
      <div className={styles.cell}>{round.tournament_round_number}</div>
      {columns.map((col) => (
        <BonusCell
          key={col.key}
          icon={col.icon}
          value={round[col.key as keyof IRoundStat] as number | string | boolean | null}
        />
      ))}
      <div className={styles.cell}>{round.played_minutes}</div>
      <div className={styles.cellRight}>{round.base_score}</div>
      <div className={`${styles.cellRight} ${styles.ts}`}>{round.total_score}</div>
      <div className={styles.roundClub}>
        {flagCode ? (
          <span className={`flag-icon flag-icon-${flagCode.toLowerCase()} ${styles.roundFlag}`} />
        ) : (
          round.club_logo_path && (
            <object data={round.club_logo_path} type="image/png">
              <DefaultLogo />
            </object>
          )
        )}
      </div>
    </div>
  );
};

const TotalRow = ({ total, columns }: { total: ISeasonTotal, columns: IBonusColumn[] }) => {
  return (
    <div className={`${styles.perfRow} ${styles.totalRow}`}>
      <div className={styles.cell}>{total.played_matches}</div>
      {columns.map((col) => (
        <BonusCell
          key={col.key}
          icon={col.icon}
          value={total[col.key as keyof ISeasonTotal]}
          alwaysCount
        />
      ))}
      <div className={styles.cell}>{total.played_minutes}</div>
      <div className={styles.cellRight}>{total.base_score}</div>
      <div className={styles.cellRight}>{total.total_score}</div>
      <div className={styles.cell} />
    </div>
  );
};

const PerformanceChart = ({ rounds }: { rounds: IRoundStat[] }) => {
  const { t } = useTranslation();

  const scored = rounds.filter((round) => Number(round.base_score) > 0);

  if (scored.length <= 1) {
    return null;
  }

  const chronological = [...scored].reverse();

  const data = {
    labels: chronological.map((r) => String(r.tournament_round_number)),
    datasets: [
      {
        label: t("players.base_score"),
        data: chronological.map((r) => r.base_score),
        borderColor: "#261FFF",
        backgroundColor: "#261FFF",
        fill: { target: "origin", above: "rgba(38, 31, 255, 0.12)" },
        tension: 0,
        pointRadius: 2,
      },
      {
        label: t("players.total_score"),
        data: chronological.map((r) => r.total_score),
        borderColor: "#FFB319",
        backgroundColor: "#FFB319",
        fill: { target: "origin", above: "rgba(255, 179, 25, 0.12)" },
        tension: 0,
        pointRadius: 2,
      },
    ],
  };

  return (
    <div className={styles.chart}>
      <div className={styles.tableTitle}>{t("players.chart")}</div>
      <div className={styles.chartView}>
        <Chart type="line" data={data} className={styles.chartArea} />
      </div>
    </div>
  );
};

const PlayerPerformance = ({
  isGoalkeeper,
  data,
  nationality,
  seasons,
  activeSeasonId,
  onSeasonChange,
}: {
  isGoalkeeper: boolean,
  data: Record<TabId, IPerfData>,
  nationality: string | null,
  seasons: ISeasonOption[],
  activeSeasonId: number | null,
  onSeasonChange: (seasonId: number) => void,
}) => {
  const { t } = useTranslation();
  const [active, setActive] = useState<TabId>("domestic");

  const flagCode = active === "international" ? nationality : null;
  const activeSeason = seasons.find((season) => season.id === activeSeasonId) ?? null;

  const tabs = [
    { id: "domestic" as const, name: t("players.domestic") },
    { id: "eurocups" as const, name: t("players.eurocups") },
    { id: "international" as const, name: t("players.international") },
  ];

  const positionColumns = isGoalkeeper ? GK_COLUMNS : OUTFIELD_COLUMNS;
  const columns = [...positionColumns, ...COMMON_COLUMNS];
  const { rounds, total } = data[active];

  return (
    <div className={`${styles.table} ${styles.perfTable}`}>
      <div className={styles.perfHead}>
        <div className={styles.tableTitle}>{t("players.performance")}</div>
        {seasons.length > 0 && (
          <div className={styles.seasonSelect}>
            <Select<ISeasonOption>
              options={seasons}
              value={activeSeason}
              getOptionValue={(option) => String(option.id)}
              formatOptionLabel={(option) => option.label}
              onChange={(option) => option && onSeasonChange((option as ISeasonOption).id)}
            />
          </div>
        )}
      </div>

      <Tabs tabs={tabs} active={active} onChange={setActive} />

      <div className={styles.perfTableWrap}>
        <div className={styles.perfInner}>
          <Header columns={columns} />
          {rounds.map((round) => (
            <RoundRow key={round.id} round={round} columns={columns} flagCode={flagCode} />
          ))}
          <TotalRow total={total} columns={columns} />
        </div>
      </div>

      <PerformanceChart rounds={rounds} />
    </div>
  );
};

export default PlayerPerformance;
