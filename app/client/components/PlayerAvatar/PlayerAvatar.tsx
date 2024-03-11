import cn from "classnames";
import kitMask from "@/assets/images/kit-small-mask.png";
import avatarMask from "@/assets/images/avatar.png";
import styles from "./PlayerAvatar.module.scss";

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
      <object className={styles.face} data={avatarSrc} type="image/png">
        <img src={avatarMask} />
      </object>
      <object className={styles.kit} data={clubKitSrc} type="image/png">
        <img src={kitMask} />
      </object>
    </div>
  );
};

export default PlayerAvatar;
