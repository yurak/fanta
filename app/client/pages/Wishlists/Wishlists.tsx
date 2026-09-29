import { useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import Skeleton from "react-loading-skeleton";
import Heading from "@/components/Heading";
import PageLayout from "@/layouts/PageLayout";
import Tabs, { ITab } from "@/ui/Tabs";
import EmptyState from "@/ui/EmptyState";
import { useWishlists } from "@/api/query/useWishlists";
import WishlistPlayers from "@/components/WishlistPlayers";
import styles from "./Wishlists.module.scss";

// One list per competition, so the tabs are the lists themselves rather than every tournament we
// run: a competition the user has wished for nobody in has nothing to show.
const Wishlists = () => {
  const { t } = useTranslation();
  const { data: wishlists, isLoading } = useWishlists();
  const [activeId, setActiveId] = useState<number | undefined>(undefined);

  const tabs = useMemo<ITab<number | undefined>[]>(
    () =>
      (wishlists ?? []).map((wishlist) => ({
        id: wishlist.id,
        name: wishlist.tournament.short_name || wishlist.tournament.name,
      })),
    [wishlists]
  );

  useEffect(() => {
    if (activeId === undefined && tabs[0]) setActiveId(tabs[0].id);
  }, [activeId, tabs]);

  const active = wishlists?.find((wishlist) => wishlist.id === activeId);

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
        <Heading title={t("wishlist.title")} />
        <EmptyState title={t("wishlist.empty_title")} description={t("wishlist.empty_text")} />
      </PageLayout>
    );
  }

  return (
    <PageLayout>
      <div className={styles.tabs}>
        <Tabs tabs={tabs} active={activeId} onChange={setActiveId} />
      </div>
      {active && <WishlistPlayers key={active.id} wishlist={active} title={t("wishlist.title")} />}
    </PageLayout>
  );
};

export default Wishlists;
