import { useTranslation } from "react-i18next";
import PlayersPageConfigurationContextProvider from "@/application/Players/PlayersPageConfigurationContext";
import PlayersPage from "@/components/PlayersPage";
import Switcher from "@/ui/Switcher";
import EmptyState from "@/ui/EmptyState";
import { ISeason } from "@/interfaces/Season";
import { IWishlist } from "@/interfaces/Wishlist";
import { useShareWishlist } from "@/api/query/useWishlists";
import styles from "./WishlistPlayers.module.scss";

// Same short form the season picker uses, so "26/27" reads the same everywhere.
const seasonLabel = ({ start_year, end_year }: ISeason) =>
  `${start_year.toString().slice(-2)}/${end_year.toString().slice(-2)}`;

const ShareSwitcher = ({ wishlist }: { wishlist: IWishlist }) => {
  const { t } = useTranslation();
  const mutation = useShareWishlist(wishlist.id);

  return (
    <div className={styles.share} title={t("wishlist.shared_hint")}>
      <Switcher
        checked={wishlist.shared}
        label={t("wishlist.shared")}
        onChange={(checked) => mutation.mutate(checked)}
      />
    </div>
  );
};

// The list reuses the players page wholesale — it is the same table, narrowed by `wishlist_id`,
// so sorting, filters and the infinite scroll all come along for free. The season picker and the
// CSV export are left out: the list is pinned to one season already, and exporting it is not a
// thing anyone asked for.
const WishlistPlayers = ({ wishlist, title }: { wishlist: IWishlist, title: React.ReactNode }) => {
  const { t } = useTranslation();

  const subtitle = `${wishlist.tournament.name} · ${seasonLabel(wishlist.season)}`;

  // Only when the list itself holds nobody. With players on it and a filter that matches none of
  // them, the ordinary "change your filters" message is the right one.
  const emptyState =
    wishlist.players_count === 0 ? (
      <EmptyState
        title={t("wishlist.list_empty_title", { tournament: wishlist.tournament.name })}
        description={wishlist.editable ? t("wishlist.list_empty_text") : t("wishlist.list_empty_other")}
      />
    ) : undefined;

  return (
    <PlayersPageConfigurationContextProvider wishlistId={wishlist.id}>
      <PlayersPage
        title={title}
        subtitle={subtitle}
        emptyState={emptyState}
        actions={
          <div className={styles.actions}>
            <span className={styles.counter}>
              {wishlist.players_count}/{wishlist.max_players}
            </span>
            {wishlist.editable && <ShareSwitcher wishlist={wishlist} />}
          </div>
        }
      />
    </PlayersPageConfigurationContextProvider>
  );
};

export default WishlistPlayers;
