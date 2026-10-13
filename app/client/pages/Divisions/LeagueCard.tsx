import { Link } from "react-router-dom";
import cn from "classnames";
import { IDivisionLeague } from "@/interfaces/Division";
import ClubLogo from "@/components/ClubLogo/ClubLogo";
import ArrowRightIcon from "@/assets/icons/arrow-right.svg";
import StarIcon from "@/assets/icons/star.svg";
import styles from "./Divisions.module.scss";

// A place is in the promotion zone when it is among the first `promotion` rows, and in the
// relegation zone when it is among the last `relegation` ones. Both are 0 in a top or bottom
// division, which is how a league with no zone at all falls out of this for free.
const zoneOf = (index: number, total: number, league: IDivisionLeague) => {
  if (league.promotion > 0 && index < league.promotion) return "promotion";
  if (league.relegation > 0 && index >= total - league.relegation) return "relegation";

  return null;
};

const LeagueCard = ({
  league,
  collapsed,
  isMine,
  myTeamIds,
}: {
  league: IDivisionLeague,
  collapsed: boolean,
  isMine: boolean,
  myTeamIds: number[],
}) => {
  return (
    <div className={styles.card}>
      <Link
        to={`/leagues/${league.id}/results`}
        className={cn(styles.cardHead, { [styles.cardHeadCollapsed]: collapsed })}
      >
        {isMine && <StarIcon className={styles.cardStar} />}
        <span className={styles.cardCode}>{league.division}</span>
        <span className={styles.cardName}>{league.name}</span>
        <ArrowRightIcon className={styles.cardArrow} />
      </Link>

      {!collapsed && (
        <div className={styles.cardBody}>
          {league.results.map((result, index) => {
            const zone = zoneOf(index, league.results.length, league);

            return (
              <Link
                key={result.id}
                to={`/teams/${result.team_id}`}
                className={cn(styles.row, { [styles.rowMine]: myTeamIds.includes(result.team_id) })}
              >
                <span
                  className={cn(styles.place, {
                    [styles.placePromotion]: zone === "promotion",
                    [styles.placeRelegation]: zone === "relegation",
                  })}
                >
                  {index + 1}
                </span>
                <span className={styles.logo}>
                  <ClubLogo src={result.team_logo} alt={result.team_name} />
                </span>
                <span className={styles.team}>
                  <span className={styles.teamName}>{result.team_name}</span>
                  <span className={styles.teamCode}>{result.team_code}</span>
                </span>
                <span className={styles.points}>{result.points}</span>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
};

export default LeagueCard;
