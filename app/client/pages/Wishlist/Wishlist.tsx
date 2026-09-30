import { useTranslation } from "react-i18next";
import { useNavigate, useParams } from "react-router-dom";
import Skeleton from "react-loading-skeleton";
import { AxiosError } from "axios";
import PageLayout from "@/layouts/PageLayout";
import EmptyState from "@/ui/EmptyState";
import WishlistPlayers from "@/components/WishlistPlayers";
import { useWishlist } from "@/api/query/useWishlists";
import ArrowLeft from "@/assets/icons/arrow_left.svg";
import styles from "./Wishlist.module.scss";

// The public address of one list. A stranger who follows the link is told the list is private
// rather than shown an empty table or a login form.
const Wishlist = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const params = useParams<{ wishlistId: string }>();
  const { data: wishlist, isLoading, error } = useWishlist(Number(params.wishlistId));

  if (isLoading) {
    return (
      <PageLayout>
        <Skeleton height={320} />
      </PageLayout>
    );
  }

  if (error) {
    const status = (error as AxiosError).response?.status;
    const title = status === 403 ? t("wishlist.private_title") : t("wishlist.empty_title");
    const description = status === 403 ? t("wishlist.private_text") : undefined;

    return (
      <PageLayout>
        <EmptyState title={title} description={description} />
      </PageLayout>
    );
  }

  if (!wishlist) return null;

  const title = wishlist.editable
    ? t("wishlist.title")
    : `${t("wishlist.title")} · ${t("wishlist.by", { name: wishlist.owner.name })}`;

  return (
    <PageLayout>
      <div className={styles.links}>
        <div
          className={styles.backButton}
          title={t("wishlist.title")}
          onClick={() => navigate("/wishlists")}
        >
          <ArrowLeft />
        </div>
      </div>
      <WishlistPlayers wishlist={wishlist} title={title} />
    </PageLayout>
  );
};

export default Wishlist;
