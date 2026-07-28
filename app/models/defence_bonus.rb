module DefenceBonus
  MIN_AVG_SCORE = 7
  MAX_AVG_SCORE = 8
  STEP = 0.25
  MAX_BONUS = 5

  module_function

  def for_scores(scores, min: MIN_AVG_SCORE, max: MAX_AVG_SCORE, step: STEP)
    return 0 if scores.empty?

    for_average(scores.sum / scores.size.to_f, min: min, max: max, step: step)
  end

  def for_average(avg, min: MIN_AVG_SCORE, max: MAX_AVG_SCORE, step: STEP)
    return 0 if avg < min
    return MAX_BONUS if avg >= max

    (((avg - min) / step) + 1).floor
  end
end
