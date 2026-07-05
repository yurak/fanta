import { BONUS_ICONS, BonusKey } from "./bonuses";
import styles from "./PlayerPage.module.scss";

const BonusCell = ({
  icon,
  value,
  alwaysCount,
}: {
  icon: BonusKey,
  value: number | string | boolean | null,
  alwaysCount?: boolean,
}) => {
  // Decimal columns arrive as strings (Rails encodes BigDecimal as a string), so coerce to a number
  const count = typeof value === "boolean" ? (value ? 1 : 0) : Number(value ?? 0);

  if (!count) {
    return (
      <div className={styles.cell}>
        <span className={styles.blank}>-</span>
      </div>
    );
  }

  const Icon = BONUS_ICONS[icon];
  const showCount = alwaysCount || count > 1;

  return (
    <div className={styles.cell}>
      <span className={styles.bonusItem}>
        <Icon />
        {showCount && <span>{`x ${count}`}</span>}
      </span>
    </div>
  );
};

export default BonusCell;
