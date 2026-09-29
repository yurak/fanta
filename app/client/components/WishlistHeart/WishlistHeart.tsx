import { useEffect, useState } from "react";
import cn from "classnames";
import { useTranslation } from "react-i18next";
import { Link } from "react-router-dom";
import { useWishlistPlayer } from "@/api/query/useWishlists";
import { IPlayerShow } from "@/interfaces/Player";
import styles from "./WishlistHeart.module.scss";

const HINT_TIMEOUT = 5_000;

// Hidden rather than disabled for a guest or a player of a competition we run no list for: the
// server decides that (`wishlistable`), so the button is only ever shown when it can work.
const WishlistHeart = ({ player }: { player: IPlayerShow }) => {
  const { t } = useTranslation();
  const mutation = useWishlistPlayer(player.id);
  const [hintFor, setHintFor] = useState<number | null>(null);

  useEffect(() => {
    if (hintFor === null) return undefined;

    const timer = setTimeout(() => setHintFor(null), HINT_TIMEOUT);

    return () => clearTimeout(timer);
  }, [hintFor]);

  if (!player.wishlistable) return null;

  const label = player.wishlisted ? t("wishlist.remove") : t("wishlist.add");

  const toggle = () => {
    const wanted = !player.wishlisted;

    mutation.mutate(wanted, {
      // Only an addition is worth pointing somewhere; a removal has nothing to go and look at.
      onSuccess: (data) => setHintFor(wanted ? data.wishlist.id : null),
    });
  };

  return (
    <div className={styles.wrap}>
      <button
        type="button"
        className={cn(styles.heart, { [styles.isEmpty]: !player.wishlisted })}
        title={label}
        aria-label={label}
        aria-pressed={player.wishlisted}
        disabled={mutation.isPending}
        onClick={toggle}
      >
        <span className={styles.icon}>❤️</span>
      </button>
      {hintFor !== null && (
        <div className={styles.hint} role="status">
          <span>{t("wishlist.added")}</span>
          <Link className={styles.hintLink} to={`/wishlists/${hintFor}`}>
            {t("wishlist.open")}
          </Link>
        </div>
      )}
    </div>
  );
};

export default WishlistHeart;
