// Tournaments carry their flag as an emoji (`Tournament#icon`), but the UI wants the real flag
// image from flag-icons-rails. The emoji already encodes the country, so the code is derived from
// it rather than stored a second time.
//
// Three shapes turn up in the data:
//   🇮🇹  a pair of regional indicators            -> "it"
//   🏴󠁧󠁢󠁥󠁮󠁧󠁿  a tag sequence (England, Wales)         -> "gb-eng"
//   🌍  a plain globe, used by the world cups    -> null, there is no flag to show
const REGIONAL_INDICATOR_BASE = 0x1f1e6;
const BLACK_FLAG = 0x1f3f4;
const TAG_BASE = 0xe0000;
const TAG_TERMINATOR = 0xe007f;

export const flagCode = (emoji?: string | null): string | null => {
  if (!emoji) return null;

  const points = Array.from(emoji).map((character) => character.codePointAt(0) ?? 0);

  if (points[0] === BLACK_FLAG) {
    const letters = points
      .slice(1)
      .filter((point) => point !== TAG_TERMINATOR)
      .map((point) => String.fromCodePoint(point - TAG_BASE))
      .join("");

    // the subdivision codes flag-icons ships are "gb-eng", "gb-wls" and the like
    return letters.length > 2 ? `${letters.slice(0, 2)}-${letters.slice(2)}` : letters || null;
  }

  const indicators = points.filter(
    (point) => point >= REGIONAL_INDICATOR_BASE && point <= REGIONAL_INDICATOR_BASE + 25
  );
  if (indicators.length !== 2) return null;

  return indicators
    .map((point) => String.fromCharCode("a".charCodeAt(0) + point - REGIONAL_INDICATOR_BASE))
    .join("");
};
