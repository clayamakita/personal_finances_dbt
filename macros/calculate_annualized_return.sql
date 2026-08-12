{% macro calculate_annualized_return() %}

CREATE OR REPLACE FUNCTION `{{ target.project }}.{{ target.dataset }}.xirr`(
  amounts ARRAY<FLOAT64>,
  dates ARRAY<STRING>
)
RETURNS FLOAT64
LANGUAGE js AS """
  if (!amounts || !dates || amounts.length !== dates.length) return null;

  var dateObjects = dates.map(function(d) { return new Date(d); });
  var minDate = new Date(Math.min.apply(null, dateObjects));

  var days = dateObjects.map(function(d) {
    return (d - minDate) / (1000 * 60 * 60 * 24);
  });

  var r = 0.1;
  var maxIterations = 100;
  var epsilon = 1e-6;

  for (var i = 0; i < maxIterations; i++) {
    var f_r = 0;
    var df_r = 0;

    for (var j = 0; j < amounts.length; j++) {
      var frac = days[j] / 365.0;
      var term = Math.pow(1 + r, frac);

      f_r += amounts[j] / term;
      df_r -= (frac * amounts[j]) / (term * (1 + r));
    }

    if (Math.abs(df_r) < 1e-12) break;

    var next_r = r - f_r / df_r;

    if (Math.abs(next_r - r) < epsilon) {
      return next_r;
    }
    r = next_r;
  }
  return r;
""";

{% endmacro %}