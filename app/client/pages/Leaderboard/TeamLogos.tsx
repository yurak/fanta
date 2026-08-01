import styles from "./Leaderboard.module.scss";

const TeamLogos = ({ logos, extra = 0 }: { logos: string[], extra?: number }) => {
  if (!logos.length) {
    return null;
  }

  return (
    <div className={styles.logos}>
      {logos.map((logo, index) => (
        <img key={index} className={styles.logo} src={logo} alt="" />
      ))}
      {extra > 0 && <span className={styles.logoMore}>{`+${extra}`}</span>}
    </div>
  );
};

export default TeamLogos;
