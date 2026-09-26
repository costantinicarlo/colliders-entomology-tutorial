# Presenter notes

## Core distinction

- Ecological process: true mosquito nuisance exists whether or not a house is sampled.
- Observation process: in this scenario, a house is sampled only if people used a bed net.
- Bed-net use is a collider: temperature and mosquito nuisance both influence it.

## Useful explanations

A simple regression can be technically correct for the observed sample and still answer the wrong question.

The target question is about mosquitoes on nights/houses. The available measurement is mosquitoes inside a net among houses that used a net. Those are not equivalent populations.

## Variations to try live

- Set `bednet_used <- rep(1L, n)` and `house_sampled <- bednet_used` before generating counts: this selection mechanism disappears.
- Set the mosquito coefficient in `logit_p_net` to zero: high nuisance no longer rescues bed-net use on hot nights.
- Vary the temperature coefficient magnitude and compare sample composition and slopes over repeated simulations; do not assume every change produces a monotonic bias response.

## Partial net entry

`bed_net_entry_rate` defaults to 0.7. Counts conditional on N attackers are
Binomial(N, p): mean Np, variance Np(1-p). Every entrant is assumed to remain
inside and be counted. The constant probability changes capture, not selection.
Compare p = 0, 0.7, and 1 while keeping the ecological and behavioural models
fixed. Sampled counts must stay between zero and the number of attackers;
unsampled counts stay `NA`. At p = 1, capture is exact but collider bias remains.
At p = 0, all sampled counts are zero, so their slope is zero despite selection.
For intermediate p, the expected count slope is p times the selected-attacker
slope. Capture variation makes the realised slope differ from this expectation.

## Discussion exercise: vary entry without changing selection

Predict the count slopes at p = 0.1, 0.3, 0.7, and 0.9, then run this from the
workspace root. It generates a baseline population, then reuses the same selected houses for 100 capture
replicates at each probability, after refreshing the baseline tutorial datasets.

```r
source("R/01_simulate.R")  # generate the population and sample from scratch
obs <- subset(houses, house_sampled == 1)
attacker_slope <- unname(coef(lm(
  true_attacking_mosquitoes ~ air_temperature_c, data = obs
))[2])
set.seed(20260924)
entry_comparison <- do.call(rbind, lapply(c(0.1, 0.3, 0.7, 0.9), function(p) {
  slopes <- replicate(100, {
    captured <- rbinom(nrow(obs), obs$true_attacking_mosquitoes, p)
    unname(coef(lm(captured ~ obs$air_temperature_c))[2])
  })
  data.frame(entry_probability = p,
             expected_slope = p * attacker_slope,
             mean_slope = mean(slopes),
             capture_sd = sd(slopes))
}))
print(entry_comparison)
```

The slope increases in expectation, while the ecological temperature effect
remains zero. Slopes are in mosquitoes per degree, so changing the capture
probability also changes the measurement scale. Optionally compare correlations
to distinguish this scale change from a standardised measure of association.
Individual capture replicates need not produce monotonically increasing slopes.

## Equal effects on the collider

Nuisance need not have a larger coefficient than temperature to induce the
association. For example, `-1 - 1.25 * tz + 1.25 * mz` still selects houses
where greater nuisance compensates for heat that discourages net use. Equal
magnitudes do not remove collider selection bias. If both coefficients have the
same sign, the variables can substitute for each other and this logistic model
instead induces a negative association among users. These are associations
created by selection, not changes in the ecological effect.

## Simulation intervals versus Monte Carlo confidence intervals

Monte Carlo simulation can produce confidence intervals, but the central 95%
of simulated slopes is not automatically a confidence interval. The distinction
is what the interval describes.

The discussion now distinguishes two designs, each with B = 200 repetitions.
Question 1 first holds the ecological population fixed and repeats observation/capture,
then regenerates temperatures and attackers as well. Questions 2–5 use regenerated
populations only. In every design, each repetition produces one slope $\hat\beta_b$.
Within a regenerated-population replicate, all scenarios share the same ecological
population; entry-rate variants also share its baseline selected houses.

The plotted interval is the empirical 2.5th to 97.5th percentile range:

$$
[Q_{0.025}(\hat\beta_b),\; Q_{0.975}(\hat\beta_b)].
$$

It estimates where approximately 95% of slopes from repeated experiments would
fall under the specified model and replication design. For a fixed population,
it describes repeated observation/capture; for regenerated populations, it also
includes ecological sampling variability. With only 200
repetitions, its estimated endpoints themselves have Monte Carlo uncertainty.

A **Monte Carlo confidence interval for the mean simulated slope** instead
quantifies how precisely the repetitions estimate the model's expected slope.
An approximate 95% interval is:

$$
\overline{\hat\beta}
\;\pm\;
t_{0.975,199}\frac{s_{\hat\beta}}{\sqrt{200}},
$$

where $s_{\hat\beta}$ is the standard deviation of the 200 simulated slopes.
This is a large-sample approximation for independent repetitions with finite
variance; the t interval is exact when the replicate slopes are normally
distributed. It answers: **How precisely have we estimated the average slope
across repeated experiments?**

| Interval | Effect of increasing the number of repetitions B |
|---|---|
| Central 95% of simulated slopes | Endpoints become more precise, but the width approaches the underlying variability between experiments |
| Confidence interval for the mean simulated slope | Width shrinks approximately as $1/\sqrt{B}$ |

Percentile intervals can support confidence inference in an appropriately
constructed bootstrap or simulation-based procedure. However, taking percentiles
alone does not establish 95% confidence coverage for a parameter; the construction
and its target must justify that interpretation.

For the fixed-population figure, use **“central 95% simulation interval, conditional on the
fixed ecological population.”** It describes observation/capture variability,
not uncertainty in the ecological temperature effect, and excludes variation
from generating new ecological populations. In the universal-use scenario,
the expected count slope conditional on this particular population is about
0.082 rather than exactly zero. A simulation interval excluding zero there
therefore does not contradict the zero ecological effect imposed by the model.

## Why the universal-coverage percentile range can exclude zero

Random net-entry error has zero expected covariance with temperature. The small
positive slope under universal coverage is inherited from the particular finite
ecological population generated for this example, not created by entry error.

Write the recorded count for house i as:

$$
C_i = pN_i + \varepsilon_i,
\qquad E[\varepsilon_i \mid T_i,N_i] = 0,
$$

where $T_i$ is temperature, $N_i$ is the number of attacking mosquitoes, and
$p=0.7$ is the entry probability. Conditional on these variables,
$C_i \sim \operatorname{Binomial}(N_i,p)$. The error variance is $N_ip(1-p)$,
so it varies with pressure, but its conditional mean is zero.

For ordinary least squares with an intercept and the fixed temperatures and
attacker counts, the count slope is:

$$
\hat\beta_C
= p\hat\beta_N
+ \frac{\sum_i (T_i-\bar T)\varepsilon_i}
       {\sum_i (T_i-\bar T)^2}.
$$

The second term has conditional expectation zero. Therefore:

$$
E[\hat\beta_C \mid \mathbf T,\mathbf N] = p\hat\beta_N.
$$

The generated population has an attacker–temperature slope of approximately
+0.117, although the generating processes are independent. Independence does
not force the realised covariance in a finite random population to be exactly
zero. For this fixed population, the expected count slope is consequently:

$$
0.7 \times 0.117 \approx 0.082.
$$

The 200 fixed-population universal-coverage repetitions keep all 6,000 temperatures and attacker
counts fixed and redraw only net entry. Their slopes cluster around 0.082,
with an empirical central 95% Monte Carlo percentile range of approximately
0.056–0.103. This range excludes zero because it describes entry variability
around the inherited finite-population slope.

There are two distinct sources of randomness:

- **Generating temperatures and attackers:** creates a chance realised
  covariance, which the first question’s conditional experiment then holds fixed.
- **Generating net entry:** adds variability with zero expected contribution
  to the slope, conditional on that population.

Regenerating the ecological population as well in each repetition produces
a universal-coverage slope distribution centred on zero in expectation. The
fixed-population range excludes that source of variation; the new comparison
figure explicitly includes it. Zero expected covariance from
entry error does not cancel the nonzero realised covariance already present
between temperature and attackers.

“Central 95% Monte Carlo percentile range” is an appropriate label here. More
explicitly: **“Monte Carlo 2.5th–97.5th percentile range across 200 capture
replicates, conditional on the fixed ecological population.”** This wording
describes the simulation distribution without implying confidence coverage for
the ecological temperature effect.

## Teaching both replication designs

Both approaches are useful because they answer different questions. Conditional
replication asks what repeated observation would produce for one realised
ecological population. Full replication asks what repeated studies would produce
under the specified generating model. A chance attacker–temperature covariance
in one finite population is not itself collider selection bias. Comparing its
universal-coverage slope with the selectively observed slope helps separate that
chance association from the selection mechanism.

For question 1, the fixed-population universal mean is approximately +0.081 with
central 95% range [0.056, 0.103]. With 200 regenerated populations, the mean is
approximately +0.0063 and the range is [−0.143, 0.164]. The latter is wider here
because it includes variation in realised attacker–temperature covariance as well
as capture noise. Neither range is a confidence interval for the ecological effect.

Under universal coverage, the law of total variance makes the distinction explicit:

$$
\operatorname{Var}(\hat\beta_C)
= E[\operatorname{Var}(\hat\beta_C \mid \mathbf T,\mathbf N)]
+ \operatorname{Var}(p\hat\beta_N).
$$

Repeated capture on one population estimates a conditional variance for that
particular population. Full replication includes both terms. It is not necessary
to force each population’s realised covariance to zero: those chance covariances
are part of the variability we want to teach.

The fresh-population design draws 6,000 house-nights per replicate, recomputes
`tz` and `mz`, and generates baseline net use. All ten scenarios are applied to
that same population before the next population is drawn. Entry-rate scenarios
reuse that replicate’s baseline selected houses, so their comparison does not
mix changes in capture with changes in membership. Other behavioural scenarios
draw their own net-use decisions. Counts are drawn independently for each
scenario, including the baseline and entry = 0.7 variants.

```r
source("R/04_discussion.R")
# One additional paired comparison; do not reset the seed inside a loop.
d <- generate_discussion_population()
observe_discussion(fixed_sample = TRUE, population = d)
observe_discussion(universal = TRUE, population = d)
observe_discussion(entry_rate = 0.9, fixed_sample = TRUE, population = d)
```

`data/discussion_replicates.csv` contains 2,400 rows: two scenarios × 200 fixed
replicates and ten scenarios × 200 fresh replicates. Group by `design` and
`scenario`; use `replicate` to pair scenarios within the fresh-population design.
`population_slope` records the realised full-population attacker slope;
`expected_slope` records entry probability times the selected-attacker slope.
The latter is the conditional expected count slope before capture noise.

Independent repeated studies can represent replication across places or times
under these assumptions. The simulation does not explicitly model spatial or
temporal dependence, changing environmental distributions, or changing causal
parameters. Those would require extending the generating model. The causal
structure and its parameters remain fixed while its realisations change.

## Question 6: adding a direct ecological temperature effect

This extension changes the DAG by adding T → M. Dependence alone would not
establish this causal arrow: a shared environmental cause could instead explain
it. Here the arrow is an explicit generating assumption. Earlier questions keep
their original independent ecological model.

For each house-night, generate independent T and Z, then:

$$
T \sim N(27, 2.8^2),\qquad Z \sim N(0, 0.65^2),
$$
$$
\log\lambda = \log(28) + Z + \beta(T-27)/2.8,
\qquad N\mid T,Z \sim \operatorname{Poisson}(\lambda).
$$

Thus exp(beta) multiplies expected attacker abundance per 2.8 °C increase.
The fixed reference scale 2.8 defines this coefficient; recomputed `tz` and `mz`
retain their original role in the behavioural logistic model. The ecological
intercept keeps expected abundance at T = 27 fixed. It does not keep marginal
mean abundance fixed as beta changes. Similarly, a nuisance coefficient of 1.75
is fixed per realised SD of pressure, not per attacking mosquito.

We generate potential counts C ~ Binomial(N, 0.7) for all houses. Universal
coverage observes all C; the selected regime reveals C only where net use is
true. This pairs both ecology and capture noise exactly. It is valid under the
toy assumption that net use changes availability, without changing attacking
pressure or entry probability. It would need revision if nets changed exposure
or ecological dynamics. Sharing potential outcomes here is a simulation design,
not a claim that both counterfactual outcomes can be observed in field data.

The example figure uses beta = 0.3 and identical panel limits. Its count axis is
log(1 + C), retaining zeros and original-count labels. Fits remain OLS on raw
counts. Displayed fitted curves omit negative predictions; all observations,
including zeros, contribute to the fits. The count-scale linear slope is a
descriptive projection of a nonlinear ecological response, not beta itself.

The sweep uses beta = −0.6, −0.3, −0.15, 0, 0.15, 0.3, 0.6, with 200 independent
populations of 6,000 house-nights per value. Regimes are paired within each
replicate; different beta values use separate fresh populations. Compare the
selected count slope to its universal count counterpart, not to the log-abundance
coefficient. `difference` records this paired contrast. All ranges are empirical
central 95% Monte Carlo percentile ranges, not confidence intervals.

At beta = −0.15, mean slopes are −1.300 (universal) and +0.724 (selected): reversal.
At −0.3 the negative slope is attenuated, from −2.710 to −1.444; at −0.6 it is
amplified in magnitude, from −6.194 to −8.307. At +0.3 the positive slope is
amplified from +2.711 to +5.697. These outcomes demonstrate why the original
positive selection association is not an additive constant to apply to every
causal model. The selection distortion changes with the ecological relationship
and distribution. The beta = 0 point reproduces the original generating model,
with different Monte Carlo realisations and therefore slightly different means.

`R/lib/ecological_effect_compute.R` generates the new data and functions;
`R/lib/ecological_effect_figures.R` renders both figures through the bilingual
build. `R/04_discussion.R` runs the new experiment after questions 1–5 using
separate seeds, preserving all earlier results. The standalone French build
also generates this experiment from scratch. No pre-computed inputs are required.

## Field data: can a Bayesian network distinguish ecology from selection?

A full Bayesian model is useful, but a posterior temperature effect that excludes
zero does not, by itself, distinguish ecological independence from an ecological
temperature effect. The first question is whether the available observations can
separate the ecological relationship from selection and measurement. This is an
**identifiability** problem: fitting a Bayesian network does not automatically
resolve it. General conditions for recovery from selection bias are discussed by
[Bareinboim, Tian and Pearl (2014)](https://ftp.cs.ucla.edu/pub/stat_ser/r425.pdf).

Distinguish three mechanisms: temperature affecting attacking mosquitoes;
temperature and mosquito pressure affecting net use; and attacking mosquitoes
entering the net and being counted. If scientists have only temperatures and
captures from net-using houses, different combinations of these mechanisms can
produce the same or very similar observed relationships. A positive association
could reflect an ecological effect, collider selection under ecological
independence, or both. More selected observations can estimate that association
precisely without necessarily identifying its origin.

Even if mosquito pressure M were measured perfectly, selection would imply:

$$
p(M\mid T,S=1)
= \frac{p(S=1\mid T,M)\,p(M\mid T)}{p(S=1\mid T)}.
$$

Here T is temperature and S = 1 denotes inclusion in the observed sample. The
observed distribution combines the ecological distribution with the selection
mechanism. Without additional information or restrictions, these factors cannot
generally be separated uniquely. Captures as an imperfect measure of pressure
add another layer. Specific parametric restrictions can sometimes identify a
model, but their contribution must be distinguished from information supplied
by the sampling design.

A narrow Bayesian posterior can depend strongly on functional forms, priors,
and capture assumptions. Its interpretation is: **given this ecological model,
selection model, measurement model, and these priors, the effect is probably in
this range.** It does not establish that the observations have ruled out all
competing explanations. Priors can regularise a weakly identified problem or
supply external information; they do not make the likelihood informative about
a distinction it cannot identify.

### What additional field information helps?

| Information | Contribution and limit |
|---|---|
| Temperature and net-use status for all eligible house-nights, including those without captures | Constrains selection by temperature; does not alone resolve selection by unobserved mosquito pressure |
| Independent pressure measurements in a probability sample of house-nights, irrespective of net use | Supplies observations outside the selected sample; the measurement method still needs calibration |
| Calibration of capture efficiency, including possible dependence on temperature, net condition, or behaviour | Helps separate abundance changes from measurement changes |
| Measurements of relevant environmental common causes, chosen using a causal graph | Helps distinguish temperature effects from confounding, subject to the adequacy of those measurements and assumptions |

Independent mosquito sampling is particularly valuable. Recording net use alone
does not guarantee recovery of the missing pressure distribution. What can be
recovered depends on the causal structure and additional information available;
see [Recovering from Selection Bias in Causal and Statistical Inference](https://ojs.aaai.org/index.php/AAAI/article/view/9074).

### How to assess a full Bayesian analysis

Fit the joint ecological–selection–measurement model using a likelihood that
accounts for the actual sampling design and missing observations. In particular,
a selected-only dataset requires accounting for selection, not treating it as an
unselected population sample. If records for all eligible houses exist, include
their selection indicators and integrate over unobserved pressure and counts as
appropriate. Unsampled counts are missing, not zero.

1. **Assess identifiability and parameter recovery.** Establish what assumptions
   identify the target effect. Simulate both zero-effect and nonzero-effect
   studies under the actual sampling design, and check whether the fitted model
   confuses ecological effects with selection or capture parameters. Successful
   recovery under one chosen model is useful but does not prove identification
   across alternative models.
2. **Check sensitivity.** Vary plausible priors, selection functions, capture
   assumptions, and ecological response shapes. Large changes in the inferred
   effect indicate dependence on assumptions that the data constrain weakly.
3. **Check predictions against independent observations.** Posterior predictive
   checks on net users assess fit to that selected sample. Predicting independently
   sampled houses provides a stronger check of the ecological explanation. Good
   selected-sample prediction alone does not establish causal validity.
4. **Report meaningful effect sizes.** Describe posterior support for effects
   large enough to matter, rather than using exclusion of exactly zero as the
   sole criterion. Under a continuous prior, the posterior probability of exactly
   zero is ordinarily zero by construction; an interval excluding zero is a
   different statement. Explicit comparisons with a point-null model require
   additional model and prior choices and still cannot repair nonidentifiability.

There is a separate causal issue even if the population association is
identified. Season, habitat, or other environmental causes may affect both
temperature and mosquito pressure. Interpreting a fitted temperature coefficient
as a causal effect requires addressing those paths and specifying the relevant
temperature contrast and time scale. A Bayesian network represents causal
assumptions only when its arrows are given that interpretation and justified;
the fitted joint distribution alone does not establish them.

Suggested discussion question: **Can the observed data distinguish ecological
effects from selection effects?** The answer is sometimes, depending on the
sampling design and identifying assumptions. Bayesian modelling expresses those
assumptions and quantifies uncertainty conditional on them; it cannot replace
missing information.

### Examples: how external calibration or restrictions can help

Information about why observations are missing can sometimes substitute for
observing the missing outcomes themselves. This does not mean that fitting a
Bayesian network creates that information. It comes from external evidence or
explicit identifying assumptions. **Calibrating capture efficiency alone does
not generally resolve pressure-dependent selection.**

#### Example 1: externally calibrated selection probabilities

For illustration, suppose pressure M is either low or high and is measured
accurately in sampled houses. A separate behavioural study establishes the
following probabilities of net use and hence selection:

| Temperature | Selection probability: low pressure | Selection probability: high pressure |
|---|---:|---:|
| Cool | 0.40 | 0.80 |
| Hot | 0.10 | 0.40 |

Nuisance encourages use, while heat discourages it. Suppose the selected field
sample contains two-thirds high-pressure houses at cool temperatures and
four-fifths at hot temperatures. The selected sample therefore suggests greater
pressure at higher temperatures.

Because the selection probabilities are known, divide the observed proportions
by their selection probabilities and renormalise within each temperature:

$$
P(M=\mathrm{high}\mid T=\mathrm{cool})
=\frac{(2/3)/0.80}{(2/3)/0.80+(1/3)/0.40}=0.50,
$$

$$
P(M=\mathrm{high}\mid T=\mathrm{hot})
=\frac{0.80/0.40}{0.80/0.40+0.20/0.10}=0.50.
$$

Thus the underlying pressure distributions are equal in this binary example.
We recover them without measuring pressure in the unsampled houses of this
particular study: the independent calibration supplied the missing information.
This is the principle of inverse-probability selection weighting; see
[Hernán and Robins, Causal Inference: What If](https://www.hsph.harvard.edu/miguel-hernan/wp-content/uploads/sites/1268/2024/04/hernanrobins_WhatIf_26apr24.pdf).

This correction requires that the external selection probabilities apply to the
current study, that every relevant category has a nonzero probability of being
selected, and that pressure is measured sufficiently well. Estimated calibration
probabilities also carry uncertainty, which should be propagated. Categories
with zero selection probability cannot be recovered by weighting alone.

In our actual example, attacking pressure is latent and captured counts are an
imperfect measurement. We cannot simply substitute captured counts into the
pressure-dependent selection formula. A joint measurement–selection model would
need adequate calibration and its own identification argument. The binary
example demonstrates the principle under accurate measurement; it does not
establish identification for every latent-pressure model.

#### Example 2: a justified restriction on the selection mechanism

Suppose independent evidence justifies the restriction:

$$
P(S=1\mid T,M)=P(S=1\mid T).
$$

For instance, in a different setting, net use might respond to temperature-related
comfort alone, with no response to nuisance. Wherever selection probability is
positive, the restriction implies:

$$
p(M\mid T,S=1)=p(M\mid T).
$$

Selection then changes the number of hot and cool observations without changing
the pressure distribution within a temperature. The selected houses can identify
the temperature–pressure relationship, subject to temperature coverage and an
adequate measurement model. This is a strong identifying restriction: it removes
pressure-dependent selection. Recovery depends on such structural assumptions;
see [Bareinboim, Tian and Pearl (2014)](https://ftp.cs.ucla.edu/pub/stat_ser/r425.pdf).

**This restriction is not justified in our exemplar study**, where nuisance
explicitly affects net use. Assuming it merely because it simplifies estimation
would be unjustified. It illustrates how a restriction can identify a relationship,
not why that restriction should be believed. Selected data alone do not generally
provide a test that establishes the restriction.

#### Example 3: capture calibration resolves a different ambiguity

Suppose selected houses show mean counts of 10 on cool nights and 20 on hot
nights. Two explanations are twice as many attacking mosquitoes with unchanged
capture probability, or unchanged attacking abundance with capture probability
increasing from 0.25 to 0.50.

If independent experiments establish p(T), and the measurement model is
C | M,T,S=1 ~ Binomial(M,p(T)), then:

$$
E[M\mid T,S=1]=\frac{E[C\mid T,S=1]}{p(T)}.
$$

For p(cool) = 0.25 and p(hot) = 0.50, the two observed means both imply 40
attacking mosquitoes on average **among selected houses**. This resolves the
abundance-versus-capture ambiguity under the stated measurement assumptions.
It assumes that capture probability at a given temperature does not additionally
vary with pressure or other unaccounted-for determinants in a way that invalidates
the factorisation of the conditional mean.

The calculation still does not recover the pressure distribution in all houses:
selection may favour different houses at different temperatures. Capture calibration
must be combined with an adequate solution to selection, such as the information
in example 1 or the justified restriction in example 2. This example also extends
the tutorial’s constant capture probability to illustrate a possible field-data
measurement problem; it does not change the simulation already presented.

The selected observations do not acquire missing information merely because a
Bayesian model is fitted. Measuring otherwise unsampled houses directly is one
route; learning the selection mechanism independently is another; imposing a
defensible identifying restriction is a third. Each contributes something beyond
the selected counts themselves. Even after recovering the population relationship,
interpreting it as a causal temperature effect requires addressing environmental
confounding.

## Final disclaimer: deliberately omitted causal pathways

All causal models explored in this presentation are **toy models**. They isolate
selected mechanisms and deliberately omit plausible pathways that deserve
investigation in a realistic field study. Adding the direct temperature effect
in question 6 does not make that model a complete causal account.

- **Seasonal confounding:** temperature ← season → mosquito pressure. Season
  represents seasonal processes that can jointly influence temperature and
  mosquito pressure. This common-cause path can generate a population association
  without a direct temperature effect on attacking abundance. A realistic causal
  model must specify relevant seasonal mechanisms and time scales; recording a
  coarse season indicator does not automatically establish adequate control.
- **Temperature-dependent capture:** temperature → `bed_net_entry_rate` →
  recorded counts. Temperature may influence mosquito behaviour and entry into
  nets. The tutorial instead fixes entry probability within each scenario.
  A field analysis should investigate whether that assumption is defensible.

With a temperature-dependent entry probability p(T), the binomial measurement
model implies, under universal coverage:

$$
E[C\mid T]=p(T)E[N\mid T].
$$

Consequently, counts can vary with temperature even if expected attacking
abundance does not. Conversely, opposing changes in abundance and entry can
mask a relationship. Calibrating capture across temperatures helps distinguish
these mechanisms. The equation assumes entry probability is p(T) for each
attacker under the stated measurement model; additional heterogeneity may
require a richer model.

Universal coverage removes the net-use selection mechanism in the tutorial,
but it does not remove seasonal confounding or temperature-dependent capture.
The universal-coverage curves are therefore benchmarks under the specified toy
model, not guaranteed estimates of an ecological temperature effect in field data.

End by emphasising that realistic inference must investigate these omitted
pathways alongside selection, using field knowledge, appropriate environmental
measurements, capture calibration, and sensitivity analyses. These are plausible
causal extensions to examine, not effects whose presence or magnitude has been
established by the simulations. An association in recorded counts need not be
an ecological temperature effect.

## What happens as baseline net use approaches zero?

Here “baseline net use” means the probability of use at average temperature and
pressure, plogis(baseline_logit). It approaches zero as baseline_logit tends to
negative infinity, with the temperature and nuisance coefficients held fixed.
Setting baseline_logit to zero instead gives a baseline probability of 0.5.

Reducing baseline net use reduces the number of observed houses and changes
sample composition. It does not turn their recorded mosquito counts into zeros.
In a fixed realised population of 6,000 house-nights, each house's selection
probability tends to zero. The expected sample size tends to zero and the
probability of an empty sample tends to one. Before that limit, fitted slopes
can be unstable; fewer than two observations at distinct temperatures cannot
identify an OLS slope with an intercept. Two observations can determine a line,
but leave no residual degrees of freedom for the usual uncertainty estimate.

**The estimated slope need not decrease toward zero as baseline use decreases.**
Eventually the finite study supplies too few observations to estimate it.
Unsampled counts are missing, not zero. A very small positive baseline
probability is also not the same as imposing zero use everywhere: high nuisance
can still make particular houses likely to use nets.

### Why a tempting rare-selection argument needs qualification

Write t and m for the standardised temperature and pressure predictors, and let

$$
P(S=1\mid t,m)=\operatorname{logit}^{-1}(a+bt+cm).
$$

For fixed t and m, as a tends to negative infinity,

$$
P(S=1\mid t,m)\approx e^a e^{bt}e^{cm}.
$$

The approximate weight factorises into separate temperature and pressure
factors. If the original population predictors are independent, and these
weights are integrable with an appropriately justified limiting argument, the
normalised tilted distribution also factorises. Under those additional
conditions, rare selection would preserve independence in the limit.

**This does not establish a zero-slope limit for the tutorial's population
model.** Its attacking counts have an unbounded Poisson–lognormal distribution
and a positive nuisance coefficient. With a fixed population-standardisation
scale, positive exponential moments of that pressure distribution are infinite:
the proposed exponential tilt cannot be normalised. The pointwise approximation
is not uniform over the high-pressure tail; extremely high-pressure houses can
retain substantial selection probabilities for any finite intercept. We cannot
interchange the rare-selection limit and population averaging without checking
these issues. The scripts also recompute standardisation within each finite
population, which must be respected in any formal limit for their exact design.

On one fixed finite population, the approximation eventually holds for all
records, but the normalised weights act on that population's realised empirical
joint distribution. It need not factorise, even though the population was
generated under independence. More importantly for the teaching example, actual
samples become empty with probability approaching one. A hypothetical weighted
distribution should not be confused with a regression estimable from those
vanishing samples.

Thus the claim that arbitrarily rare net use necessarily removes the
selection-induced slope is not warranted for this model. The finite-study
conclusion is sufficient: fewer observations, changing composition, and eventual
loss of estimability. Simulations exploring very low use should report empty or
unusable samples explicitly; summarising only estimable slopes additionally
conditions on obtaining a usable sample.

### Contrast with zero net entry

| Setting | What happens to the observations? | Consequence for the count slope |
|---|---|---|
| Net use imposed to be zero for every house | No houses are sampled; counts are missing | No slope can be fitted |
| Net-entry probability is zero, with houses still sampled | Every sampled house has an observed zero count | OLS slope is exactly zero if sampled temperatures vary |

At zero entry, captures contain no information about attacking abundance or its
relationship with temperature, despite the descriptive count slope being zero.
Pearson correlation is undefined because count variance is zero. This differs
from zero use, where the absence of observations prevents fitting the slope at
all.

Suggested wording: **As baseline net use decreases, fewer houses are observed
and the selected sample changes composition. The estimated temperature slope
need not decrease toward zero; eventually the finite study contains too few
observations to estimate it.**

## Why −1, and why extend the intercept sensitivity analysis?

The default baseline intercept is now −1: a simple illustrative value, not a
field estimate or a mathematically privileged choice. It gives plogis(−1) =
26.9% use at mean temperature and pressure. This is a conditional probability,
not population-wide coverage. The sensitivity grid uses unit steps from −5 to
+1, plus the extreme case −10; the entire grid is not an arithmetic progression
because the first gap is five units. Zero is now included (50% at mean predictors).

The original lower bound −2 was a limited teaching range, not a scientific
threshold. Question 4 now compares −10, −5, −4, −3, −2, −1, 0 and +1, using 200
fresh populations and pairing intercepts within each population. The expanded
experiment has its own seed and files. All results were regenerated after the
default changed to −1; numerical summaries from earlier runs are superseded.
The old three-point intercept results remain in discussion_summary.csv for
reproducibility; the displayed Q4 results now use intercept_summary.csv.

At −5, the conditional baseline probability is 0.67%, but the mean selected
sample is 267.7 of 6,000 houses (4.46%). High-pressure houses can still have
substantial use probabilities. Selected houses average 94.6 attackers, versus
51.9 at −1. The mean count slope is +4.495 with central 95% Monte Carlo range
[2.987, 5.947], versus +2.384 and [1.973, 2.762] at −1 in this experiment.
The wider range illustrates increased variability as the sample shrinks.

The extended range does **not** show a turning point in the mean slope or a
failure to estimate slopes: the mean remains monotonic across the tested values,
and every replicate is estimable. At −5, the smallest sample has 235 houses.
It would therefore be inaccurate to describe −5 as already reaching the
empty-sample limit or demonstrating a non-monotonic slope response. Nonlinearity
of the inverse-logit probability does not itself imply non-monotonicity of the
selected regression slope. The pattern observed here is not a general theorem
that lower baseline use always increases selection bias.

The sampler now returns a missing slope for samples with fewer than two records
or no temperature variation. The extended experiment retains every replicate and
exports valid_slopes, empty_samples, and min_sample_n. If the range is extended
further and unestimable replicates arise, report their frequency: slope summaries
then describe only the estimable replicates. Do not silently discard those
failures or turn missing slopes into zeros.

### Extending the baseline logit to −10

The −10 case is added on the same 200 populations with a separate random stream,
preserving the main sweep’s random stream within the current build. Changing
the default and sweep grid nevertheless requires a fresh build. Its probability at average temperature
and pressure is plogis(−10) = 0.00454%. Yet mean coverage is 0.365%: 21.88 of
6,000 houses, ranging from 14 to 32 across replicates. Selected houses average
181.1 attacking mosquitoes. Strong nuisance effects mean that high-pressure
houses can still be sampled despite the extremely low baseline probability.

The mean slope is +5.801, with central 95% Monte Carlo percentile range
[−0.219, +13.857]. Six of 200 slopes (3%) are negative. This illustrates
substantial instability of the realised slope, not failure to fit a slope:
all 200 remain estimable and none of the samples is empty. The sequence of mean
slopes still does not turn downward over the tested intercept values. Values
between −10 and −5 were not simulated; connecting lines are only visual guides.
These percentile ranges are not confidence intervals or tests of the ecological
effect, which remains zero in this experiment.

The extended Q4 outputs now contain 1,600 rows over eight intercepts. The
previous statements about the −5 to +1 range remain valid; −10 exposes much
larger variation without yet reaching the empty-sample limit.

## Keeping the decks in sync

Use the two `colliders_entomology_*.md` files under `docs_EN/current/` and
`docs_FR/current/`. Rebuild with `Rscript R/run_all.R` after a model change.
Numerical tables in the decks must then be updated in both languages. The
additional 100-capture exercise above is exploratory; the answer slides use
the 200-replicate, fixed-seed results from `R/04_discussion.R`.
