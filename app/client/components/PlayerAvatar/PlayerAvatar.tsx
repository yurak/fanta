import kitMask from "@/assets/images/kit-small-mask.png";
import avatarMask from "@/assets/images/avatar.png";
import styles from "./PlayerAvatar.module.scss";

const PlayerAvatar = ({ avatarSrc, clubKitSrc }: { avatarSrc: string, clubKitSrc: string }) => {
  return (
    <div className={styles.avatar}>
      <div className={styles.face}>
        <object data={avatarSrc} type="image/png">
          <img src={avatarMask} />
        </object>
      </div>
      <div className={styles.kit}>
        <object data={clubKitSrc} type="image/png">
          <img src={kitMask} />
        </object>
      </div>
    </div>
  );
};

export default PlayerAvatar;
