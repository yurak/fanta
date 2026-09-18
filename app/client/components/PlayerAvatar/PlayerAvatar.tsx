import cn from "classnames";
import kitMask from "@/assets/images/kit-small-mask.png";
import avatarMask from "@/assets/images/avatar.png";
import styles from "./PlayerAvatar.module.scss";
import Skeleton from "react-loading-skeleton";

const PlayerAvatar = ({
  avatarSrc,
  clubKitSrc,
  className,
}: {
  avatarSrc: string,
  clubKitSrc: string,
  className?: string,
}) => {
  return (
    <div className={cn(styles.avatar, className)}>
      <img
        className={styles.face}
        src={avatarSrc}
        alt=""
        onError={(e) => {
          e.currentTarget.onerror = null;
          e.currentTarget.src = avatarMask;
        }}
      />
      <img
        className={styles.kit}
        src={clubKitSrc}
        alt=""
        onError={(e) => {
          e.currentTarget.onerror = null;
          e.currentTarget.src = kitMask;
        }}
      />
    </div>
  );
};

export const PlayerAvatarSkeleton = ({ className }: { className?: string }) => (
  <div className={cn(styles.avatar, className)}>
    <Skeleton className={styles.skeleton} />
  </div>
);

export default PlayerAvatar;
