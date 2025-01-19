#' local indicator of stratified power
#'
#' @param formula A formula.
#' @param data An `sf` object of observation data.
#' @param bandwidth The bandwidth employed to select "local" data.
#' @param discvar Name of continuous variable columns that need to be discretized. Noted that
#' when `formula` has `discvar`, `data` must have these columns. By default, all independent
#' variables are used as `discvar`.
#' @param discnum (optional) A vector of number of classes for discretization. Default is `3:8`.
#' @param discmethod (optional) A vector of methods for discretization, default is using
#' `c("sd","equal","geometric","quantile","natural")` by invoking `sdsfun`.
#' @param cores (optional) Positive integer (default is 1). When cores are greater than 1, use
#' multi-core parallel computing.
#' @param ... (optional) Other arguments passed to `gdverse::gd_opttunidisc()`. A useful parameter
#' is `seed`, which is used to set the random number seed.
#'
#' @return A `tibble`.
#' @export
#'
#' @examples
#' gtc = readr::read_csv(system.file("extdata/gtc.csv", package = "localsp"))
#' gtc
#' gtc = sf::st_as_sf(gtc, coords = c("X","Y"), crs = 4326)
#' gtc
#'
#' \donttest{
#' ## The following code takes a long time to run:
#' lisp(GTC ~ ., data = gtc, bandwidth = 6182954, cores = 6)
#' }
lisp = \(formula, data, bandwidth, discvar = NULL, discnum = 3:8,
         discmethod = c("sd", "equal", "geometric", "quantile", "natural"),
         cores = 1, ...){
  doclust = FALSE
  if (cores > 1) {
    doclust = TRUE
    cl = parallel::makeCluster(cores)
    on.exit(parallel::stopCluster(cl), add=TRUE)
  }

  distmat = sdsfun::sf_distance_matrix(data)
  data = sf::st_drop_geometry(data)

  calcul_localq = \(rowindice,formula,data,bw,discvar,discn,discm,...){
    localdf = data[which(distmat[rowindice,] <= bw),]
    res = gdverse::opgd(formula, data = localdf, discvar = discvar, discnum = discn,
                        discmethod = discm, cores = 1, ...)$factor
    names(res) = c("variable","pd","sig")
    res = tidyr::pivot_longer(res,2:3,names_to = "qn",values_to = "qv")
    localpd = res$qv
    names(localpd) = paste0(res$qn,"_",res$variable)
    localpd = tibble::as_tibble_row(localpd)
    localpd$rid = rowindice
    return(localpd)
  }

  if (doclust) {
    out_g = parallel::parLapply(cl,1:nrow(data),calcul_localq,formula,data,bandwidth,
                                discvar,discnum,discmethod,...)
    out_g = tibble::as_tibble(do.call(rbind, out_g))
  } else {
    out_g = purrr::map_dfr(1:nrow(data),calcul_localq,formula,data,bandwidth,
                           discvar,discnum,discmethod,...)
  }

  out_g = out_g |>
    dplyr::arrange(rid) |>
    dplyr::select(-rid)
  return(out_g)
}
