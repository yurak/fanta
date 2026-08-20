import { ReactNode } from "react";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { useMediaQuery } from "usehooks-ts";
import cn from "classnames";
import PageLayout from "@/layouts/PageLayout";
import PlayerAvatar from "@/components/PlayerAvatar";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import Table, { IColumn } from "@/ui/Table";
import { useAuctionDrops, useUpdateDrops } from "@/api/query/useAuctionDrops";
import { FormState, IDropPlayer } from "@/interfaces/AuctionDrops";
import { Position } from "@/interfaces/Position";
import styles from "./AuctionDrops.module.scss";

const KNOWN_POSITIONS = new Set<string>(Object.values(Position));

const FORM_CLASS: Record<FormState, string> = {
  empty: styles.formEmpty,
  skipped: styles.formSkipped,
  out: styles.formOut,
  bench: styles.formBench,
  part: styles.formPart,
  full: styles.formFull,
};

// order shown in the hover legend that decodes the form-cell colors
const FORM_LEGEND: FormState[] = ["full", "part", "bench", "out", "skipped", "empty"];

const formatDeadline = (iso: string, locale: string) =>
  new Date(iso).toLocaleString(locale, {
    weekday: "short", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit", hour12: false,
  });

const timeLeft = (iso: string) => {
  const ms = new Date(iso).getTime() - Date.now();
  if (ms <= 0) return null;
  return { hours: Math.floor(ms / 3_600_000), minutes: Math.floor((ms % 3_600_000) / 60_000) };
};

const playerPositions = (player: IDropPlayer) => player.positions.filter((position) => KNOWN_POSITIONS.has(position));

const AuctionDrops = () => {
  const params = useParams<{ leagueId: string, auctionId: string }>();
  const leagueId = Number(params.leagueId);
  const auctionId = Number(params.auctionId);
  const { data, isLoading } = useAuctionDrops(leagueId, auctionId);
  const update = useUpdateDrops(leagueId, auctionId);
  const { t, i18n } = useTranslation();
  const isMobile = useMediaQuery("(max-width: 768px)");

  const selectedIds = data ? data.players.filter((p) => p.status === "transferable").map((p) => p.id) : [];
  const leftPlayers = data ? data.players.filter((p) => p.status === "left") : [];
  const droppedPlayers = data ? data.players.filter((p) => p.status === "transferable") : [];
  const atLimit = data ? data.team.players_dropped >= data.team.available_transfers : false;

  const toggle = (player: IDropPlayer) => {
    const next = new Set(selectedIds);
    if (next.has(player.id)) {
      next.delete(player.id);
    } else {
      if (atLimit) return;
      next.add(player.id);
    }
    update.mutate([...next]);
  };

  const renderForm = (player: IDropPlayer, className?: string): ReactNode => (
    <span className={cn(styles.form, className)}>
      {(player.form ?? []).map((cell, index) => (
        <span key={index} className={cn(styles.formCell, FORM_CLASS[cell.state])}>{cell.score}</span>
      ))}
      {(player.form?.length ?? 0) > 0 && (
        <span className={styles.formLegend} role="tooltip">
          {FORM_LEGEND.map((state) => (
            <span key={state} className={styles.formLegendRow}>
              <span className={cn(styles.formLegendSwatch, FORM_CLASS[state])} />
              <span className={styles.formLegendLabel}>{t(`players.form_legend.${state}`)}</span>
            </span>
          ))}
        </span>
      )}
    </span>
  );

  const renderStatus = (player: IDropPlayer, iconOnly: boolean): ReactNode => {
    if (player.status === "left") {
      return <span className={cn(styles.leftBadge, { [styles.statusIcon]: iconOnly })}>{t("auction_drops.left")}</span>;
    }

    const dropped = player.status === "transferable";

    return (
      <button
        type="button"
        className={cn(styles.dropBtn, { [styles.droppedBtn]: dropped, [styles.statusIcon]: iconOnly })}
        disabled={atLimit && !dropped}
        aria-label={dropped ? t("auction_drops.dropped") : t("auction_drops.drop")}
        onClick={(e) => {
          toggle(player);
          e.currentTarget.blur();
        }}
      >
        {iconOnly ? (dropped ? "✕" : "✓") : (dropped ? t("auction_drops.dropped") : t("auction_drops.drop"))}
      </button>
    );
  };

  const columns: IColumn<IDropPlayer>[] = [
    {
      dataKey: "name",
      title: t("auction_drops.player"),
      className: styles.nameCell,
      dataClassName: styles.nameDataCell,
      render: (player) => (
        <a className={styles.player} href={`/players/${player.id}`}>
          <PlayerAvatar avatarSrc={player.avatar_path} clubKitSrc={player.kit_path} className={styles.avatar} />
          <span className={styles.name}>
            <span className={styles.lastName}>{player.name}</span>
            <span className={styles.firstName}>{player.first_name}</span>
          </span>
        </a>
      ),
    },
    {
      dataKey: "position",
      title: t("auction_drops.positions"),
      className: styles.positionsCell,
      render: (player) => {
        const positions = playerPositions(player);
        return positions.length > 0 ? <PlayerPositions position={positions} /> : null;
      },
    },
    {
      dataKey: "appearances",
      title: t("auction_drops.appearances"),
      align: "right",
      noWrap: true,
      className: styles.appsCell,
      render: (p) => p.appearances,
    },
    {
      dataKey: "rating",
      title: t("auction_drops.rating"),
      align: "right",
      noWrap: true,
      className: styles.ratingCell,
      render: (p) => <span className={styles.strong}>{p.rating}</span>,
    },
    {
      dataKey: "form",
      title: t("auction_drops.form"),
      className: styles.formColumn,
      render: (player) => renderForm(player),
    },
    {
      dataKey: "club",
      title: t("auction_drops.club"),
      align: "center",
      className: styles.clubCell,
      render: (p) => (p.club_logo_path ? <span className={styles.logo}><img src={p.club_logo_path} alt="" /></span> : "-"),
    },
    {
      dataKey: "price",
      title: t("auction_drops.price"),
      align: "right",
      noWrap: true,
      className: styles.priceCell,
      render: (p) => <span className={styles.strong}>{p.price != null ? `${p.price}M` : "—"}</span>,
    },
    {
      dataKey: "status",
      title: t("auction_drops.status"),
      align: "center",
      className: styles.statusCell,
      render: (player) => renderStatus(player, false),
    },
  ];

  const mobileItem = (player: IDropPlayer) => {
    const positions = playerPositions(player);

    return (
      <div key={player.player_team_id ?? `left-${player.id}`} className={styles.mobileItem}>
        <a className={styles.mobileAvatarLink} href={`/players/${player.id}`}>
          <PlayerAvatar avatarSrc={player.avatar_path} clubKitSrc={player.kit_path} className={styles.mobileAvatar} />
        </a>
        <div className={styles.mobileInfo}>
          <div className={styles.mobileTop}>
            <a className={styles.mobileName} href={`/players/${player.id}`}>
              <span className={styles.mobileNameText}>{player.first_name} {player.name}</span>
            </a>
            <span className={styles.mobilePrice}>{player.price != null ? `${player.price}M` : "—"}</span>
          </div>
          <div className={styles.mobileBottom}>
            {positions.length > 0 && (
              <span>
                <PlayerPositions position={positions} />
              </span>
            )}
            {player.club_logo_path && (
              <>
                <span className={styles.mobileDivider} />
                <span className={styles.mobileLogo}><img src={player.club_logo_path} alt="" /></span>
              </>
            )}
            <span className={styles.mobileDivider} />
            <span className={styles.mobileMeta}>{player.appearances} {t("auction_drops.apps_short")}</span>
            <span className={styles.mobileDivider} />
            <span className={styles.mobileMeta}>{player.rating}</span>
          </div>
        </div>
        {renderStatus(player, true)}
      </div>
    );
  };

  return (
    <PageLayout withSidebar>
      <div className={styles.page}>
        <div className={styles.topbar}>
          <a className={styles.header} href={`/leagues/${leagueId}/auctions`}>
            <span className={styles.back}>←</span>
            <span className={styles.title}>{t("auction_drops.auction", { number: data?.auction.number ?? "" })}</span>
          </a>
          {update.isPending ? (
            <span className={styles.saving}>🔄 {t("auction_drops.saving")}</span>
          ) : update.isSuccess ? (
            <span className={styles.saved}>
              ✅ {t("auction_drops.autosaved")}
              <span className={styles.tooltip}>{t("auction_drops.autosave_hint")}</span>
            </span>
          ) : null}
        </div>

        {isLoading || !data ? (
          <div className={styles.loading}>{t("common.loading")}</div>
        ) : (
          <>
            <div className={styles.banner}>
              <div className={styles.bannerTop}>
                <div className={styles.phase}>
                  <span className={styles.phaseName}>{t("auction_drops.dropping_phase")}</span>
                  <span className={styles.ongoing}>🚀 {t("auction_drops.ongoing")}</span>
                </div>
                {data.auction.deadline && (
                  <div className={styles.deadline}>
                    ☠️ {t("auction_drops.deadline")}: {formatDeadline(data.auction.deadline, i18n.language)}
                    {timeLeft(data.auction.deadline) && (
                      <span className={styles.remaining}> ({t("auction_drops.time_left", timeLeft(data.auction.deadline)!)})</span>
                    )}
                  </div>
                )}
              </div>

              <div className={styles.stats}>
                <span className={styles.stat}>
                  📕 {t("auction_drops.players_dropped")}
                  <b className={styles.badge}>{data.team.players_dropped}/{data.team.available_transfers}</b>
                </span>
                <span className={styles.stat}>
                  🧍 {t("auction_drops.players_left")}
                  <b className={styles.badge}>{data.team.players_left}</b>
                </span>
                <span className={styles.sep} />
                <span className={styles.stat}>
                  💰 {t("auction_drops.balance")}
                  <b className={styles.badge}>{data.team.budget}M</b>
                </span>
                <span className={styles.stat}>
                  📈 {t("auction_drops.income")}
                  <b className={cn(styles.badge, styles.green)}>{data.team.income}M</b>
                </span>
                <span className={styles.stat}>
                  💼 {t("auction_drops.possible_balance")}
                  <b className={cn(styles.badge, styles.purple)}>{data.team.possible_budget}M</b>
                </span>
              </div>

              {(droppedPlayers.length > 0 || leftPlayers.length > 0) && (
                <div className={styles.chips}>
                  {leftPlayers.map((player) => (
                    <span key={player.id} className={cn(styles.chip, styles.chipLeft)}>
                      <PlayerAvatar avatarSrc={player.avatar_path} clubKitSrc={player.kit_path} className={styles.chipAvatar} />
                      {player.name}
                    </span>
                  ))}
                  {droppedPlayers.map((player) => (
                    <span key={player.id} className={styles.chip}>
                      <PlayerAvatar avatarSrc={player.avatar_path} clubKitSrc={player.kit_path} className={styles.chipAvatar} />
                      {player.name}
                      <button type="button" className={styles.chipRemove} onClick={() => toggle(player)}>✕</button>
                    </span>
                  ))}
                </div>
              )}
            </div>

            {isMobile ? (
              <div className={styles.mobileList}>{data.players.map(mobileItem)}</div>
            ) : (
              <Table
                rounded
                dataSource={data.players}
                columns={columns}
                rowKey={(player) => player.player_team_id ?? `left-${player.id}`}
              />
            )}
          </>
        )}
      </div>
    </PageLayout>
  );
};

export default AuctionDrops;
