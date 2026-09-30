import cn from "classnames";
import { useTranslation } from "react-i18next";
import Skeleton from "react-loading-skeleton";
import PageLayout from "@/layouts/PageLayout";
import EmptyState from "@/ui/EmptyState";
import { useWishlists } from "@/api/query/useWishlists";
import { IWishlist } from "@/interfaces/Wishlist";
import ArrowIcon from "@/assets/icons/arrow_left.svg";
import styles from "./Wishlists.module.scss";

const seasonLabel = ({ start_year, end_year }: { start_year: number, end_year: number }) =>
  `${start_year}-${end_year}`;

const WishlistRow = ({ wishlist }: { wishlist: IWishlist }) => {
  const { t } = useTranslation();

  return (
    <a href={`/wishlists/${wishlist.id}`}>
      <div className={styles.row}>
        <div className={styles.iconWrapper}>
          <div className={styles.icon}>
            <img src={wishlist.tournament.logo} alt="" />
          </div>
        </div>
        <div className={styles.item}>
          <div className={styles.name}>{wishlist.tournament.name}</div>
          <div className={styles.players}>
            {wishlist.players_count}/{wishlist.max_players}
          </div>
          <div className={cn(styles.badge, { [styles.badgeShared]: wishlist.shared })}>
            {t(wishlist.shared ? "wishlist.public" : "wishlist.private")}
          </div>
          <div className={styles.season}>{seasonLabel(wishlist.season)}</div>
          <div className={styles.arrow}>
            <ArrowIcon height={24} width={24} />
          </div>
        </div>
      </div>
    </a>
  );
};

// A list rather than tabs: every wishlist keeps its own address, so a link to one opens that one
// instead of whatever the page happened to select.
const Wishlists = () => {
  const { t } = useTranslation();
  const { data: wishlists, isLoading } = useWishlists();

  if (isLoading) {
    return (
      <PageLayout>
        <Skeleton height={320} />
      </PageLayout>
    );
  }

  if (!wishlists || wishlists.length === 0) {
    return (
      <PageLayout>
        <div className={styles.head}>
          <div className={styles.pageTitle}>{t("wishlist.title")}</div>
        </div>
        <EmptyState title={t("wishlist.empty_title")} description={t("wishlist.empty_text")} />
      </PageLayout>
    );
  }

  return (
    <PageLayout>
      <div className={styles.head}>
        <div className={styles.pageTitle}>{t("wishlist.title")}</div>
      </div>
      <div className={styles.block}>
        {wishlists.map((wishlist) => (
          <WishlistRow key={wishlist.id} wishlist={wishlist} />
        ))}
      </div>
    </PageLayout>
  );
};

export default Wishlists;
