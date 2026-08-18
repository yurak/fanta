import { Fragment, useState } from "react";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { useMediaQuery } from "usehooks-ts";
import cn from "classnames";
import { useAuctions } from "@/api/query/useAuctions";
import AuctionRow from "./AuctionRow";
import styles from "./AuctionsIndex.module.scss";

const AuctionsIndex = () => {
  const params = useParams<{ leagueId: string }>();
  const leagueId = Number(params.leagueId);
  const { data } = useAuctions(leagueId);
  const { t } = useTranslation();
  const isMobile = useMediaQuery("(max-width: 768px)");
  const [showUpcoming, setShowUpcoming] = useState(false);

  return (
    <div className={cn("page-info", styles.page)}>
      <div className={styles.head}>
        <div className={styles.pageTitle}>{t("auction.index.auctions")}</div>
        <div className={styles.switcher}>
          <div
            className={cn("checkbox-block", { "checkbox-on-true": showUpcoming })}
            onClick={() => setShowUpcoming((value) => !value)}
          >
            <div className="checkbox-item" />
          </div>
        </div>
        <div className={styles.switcherText}>{t("auction.index.show_upcoming")}</div>
      </div>

      <div className={styles.block}>
        {data?.auctions.map((entry, entryIndex) => (
          <Fragment key={entryIndex}>
            {entry.rows.map((row, rowIndex) => {
              const auctionRow = <AuctionRow row={row} showIcon={isMobile} />;

              // the main row of an upcoming auction slides open/closed with "Show upcoming"
              if (entry.hidden && rowIndex === 0) {
                return (
                  <div
                    key={rowIndex}
                    className={cn(styles.collapsible, { [styles.collapsibleOpen]: showUpcoming })}
                  >
                    <div className={styles.collapsibleInner}>{auctionRow}</div>
                  </div>
                );
              }

              return <Fragment key={rowIndex}>{auctionRow}</Fragment>;
            })}
          </Fragment>
        ))}
      </div>
    </div>
  );
};

export default AuctionsIndex;
