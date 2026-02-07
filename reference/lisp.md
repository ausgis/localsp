# local indicator of stratified power

local indicator of stratified power

## Usage

``` r
lisp(
  formula,
  data,
  threshold,
  distmat,
  discvar = NULL,
  discnum = 3:8,
  discmethod = c("sd", "equal", "geometric", "quantile", "natural"),
  cores = 1,
  ...
)
```

## Arguments

- formula:

  A formula.

- data:

  The observation data.

- threshold:

  The distance threshold employed to select "local" data.

- distmat:

  The distance matrices.

- discvar:

  (optional) Name of continuous variable columns that need to be
  discretized. Noted that when `formula` has `discvar`, `data` must have
  these columns. By default, all independent variables are used as
  `discvar`.

- discnum:

  (optional) A vector of number of classes for discretization. Default
  is `3:8`.

- discmethod:

  (optional) A vector of methods for discretization, default is using
  `c("sd","equal","geometric","quantile","natural")` by invoking
  `sdsfun`.

- cores:

  (optional) Positive integer (default is 1). When cores are greater
  than 1, use multi-core parallel computing.

- ...:

  (optional) Other arguments passed to
  [`gdverse::gd_optunidisc()`](https://stscl.github.io/gdverse/reference/gd_optunidisc.html).
  A useful parameter is `seed`, which is used to set the random number
  seed.

## Value

A `tibble`.

## Examples

``` r
gtc = readr::read_csv(system.file("extdata/gtc.csv", package = "localsp"))
#> Rows: 908 Columns: 11
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> dbl (11): X, Y, GTC, Slope, Elev, LakeArea, WinTem, SumTem, Pre, Aspect, Sur...
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
gtc
#> # A tibble: 908 × 11
#>        X     Y    GTC  Slope  Elev LakeArea    WinTem  SumTem   Pre   Aspect
#>    <dbl> <dbl>  <dbl>  <dbl> <dbl>    <dbl>     <dbl>   <dbl> <dbl>    <dbl>
#>  1  75.7  34.5 -0.766 0.0369  139.    4750.  0.00245   0.318  14.3  0.000233
#>  2  76.1  34.3 -0.948 0.124   137.    4559.  0.00131   0.281  12.6  0.000379
#>  3  90.2  28.1 -2.05  0.411   154.    4428.  0.000229 -0.192   7.70 0.000429
#>  4  72.7  35.7 -0.525 0.0101  296.    4272.  0.00215   0.234  17.1  0.00130 
#>  5  88.7  28.0 -0.950 0.0597  229.    5845.  0.000472  0.0204 28.7  0.00174 
#>  6  88.7  28.0 -1.88  0.991   137.    5371.  0.000472 -0.0492 16.3  0.00174 
#>  7  88.7  28.0 -2.55  1.28    126.    5477.  0.000472 -0.294  14.5  0.00174 
#>  8  75.4  35.4 -0.909 0.0444  217.    4691.  0.00155   0.326  17.3  0.00175 
#>  9  96.5  29.5 -3.94  0.406   161.    3912. -0.000868  0.0490  7.88 0.00177 
#> 10  71.9  36.3 -0.819 0.0122  153.    4066. -0.000529 -0.0356  6.40 0.00178 
#> # ℹ 898 more rows
#> # ℹ 1 more variable: SurAlbedo <dbl>

# \donttest{
# Sample 100 observations from the original data to save runtime;
# This is unnecessary in practice;
set.seed(42)
gtc1 = gtc[sample.int(nrow(gtc),size = 100),]
distmat = as.matrix(dist(gtc1[, c("X","Y")]))
gtc1 = gtc1[, -c(1,2)]
gtc1
#> # A tibble: 100 × 9
#>       GTC   Slope  Elev LakeArea     WinTem  SumTem   Pre  Aspect SurAlbedo
#>     <dbl>   <dbl> <dbl>    <dbl>      <dbl>   <dbl> <dbl>   <dbl>     <dbl>
#>  1 -3.00  0.194   121.     5125.  0.000359   0.147   7.18 0.0325   0.00310 
#>  2 -1.17  0.0569  107.     5090.  0.00170    0.248  14.6  0.0251  -0.0175  
#>  3 -0.413 0.0585  119.     5639. -0.00149    0.109  29.7  0.0170   0.000883
#>  4 -0.718 0.0877  279.     5396. -0.00104    0.114  25.3  0.0116   0.0114  
#>  5 -1.21  0.0234  159.     5438. -0.000516  -0.0733 18.4  0.0208   0.0177  
#>  6 -0.358 0.0171  111.     5014.  0.00194    0.323  14.8  0.0169   0.00164 
#>  7 -0.703 0.0146  263.     5831.  0.0000967  0.138  20.5  0.0352   0.0110  
#>  8 -0.415 0.177    90.1    5704. -0.00155    0.192  12.7  0.00856 -0.00664 
#>  9 -0.220 0.0144   80.2    5816. -0.00169    0.132  24.3  0.0161  -0.00377 
#> 10 -1.01  0.00602  97.2    5419.  0.000879   0.118  12.2  0.0245  -0.00623 
#> # ℹ 90 more rows

# Use 2 cores for parallel computing;
# Increase cores in practice to speed up;
lisp(GTC ~ ., data = gtc1, threshold = 8, distmat = distmat,
     discnum = 3:5, discmethod = "quantile", cores = 2)
#> # A tibble: 100 × 101
#>      rid pd_Aspect sig_Aspect pd_Elev sig_Elev pd_LakeArea sig_LakeArea pd_Pre
#>    <int>     <dbl>      <dbl>   <dbl>    <dbl>       <dbl>        <dbl>  <dbl>
#>  1     1    0.0491    0.696    0.0379    0.416      0.102    0.336       0.380
#>  2     2    0.204     0.0748   0.113     0.306      0.267    0.0244      0.276
#>  3     3    0.0788    0.487    0.0274    0.872      0.0783   0.183       0.418
#>  4     4    0.342     0.00646  0.144     0.284      0.659    0.00000310  0.443
#>  5     5    0.342     0.00646  0.144     0.284      0.659    0.00000310  0.443
#>  6     6    0.153     0.171    0.0298    0.723      0.0578   0.651       0.397
#>  7     7    0.156     0.136    0.0352    0.860      0.0674   0.660       0.447
#>  8     8    0.0788    0.487    0.0274    0.872      0.0783   0.183       0.418
#>  9     9    0.108     0.346    0.0280    0.879      0.125    0.162       0.452
#> 10    10    0.156     0.136    0.0352    0.860      0.0674   0.660       0.447
#> # ℹ 90 more rows
#> # ℹ 93 more variables: sig_Pre <dbl>, pd_Slope <dbl>, sig_Slope <dbl>,
#> #   pd_SumTem <dbl>, sig_SumTem <dbl>, pd_SurAlbedo <dbl>, sig_SurAlbedo <dbl>,
#> #   pd_WinTem <dbl>, sig_WinTem <dbl>, Aspect_Elev_Interaction <chr>,
#> #   Aspect_LakeArea_Interaction <chr>, Aspect_Pre_Interaction <chr>,
#> #   Aspect_Slope_Interaction <chr>, Aspect_SumTem_Interaction <chr>,
#> #   Aspect_SurAlbedo_Interaction <chr>, Aspect_WinTem_Interaction <chr>, …
# }
```
