#' local indicator of stratified power
#'
#' @param formula A formula.
#' @param data The observation data.
#' @param threshold The distance threshold employed to select "local" data.
#' @param distmat The distance matrices.
#' @param discvar (optional) Name of continuous variable columns that need to be discretized. Noted
#' that when `formula` has `discvar`, `data` must have these columns. By default, all independent
#' variables are used as `discvar`.
#' @param discnum (optional) A vector of number of classes for discretization. Default is `3:8`.
#' @param discmethod (optional) A vector of methods for discretization, default is using
#' `c("sd","equal","geometric","quantile","natural")` by invoking `sdsfun`.
#' @param cores (optional) Positive integer (default is 1). When cores are greater than 1, use
#' multi-core parallel computing.
#' @param ... (optional) Other arguments passed to `gdverse::gd_optunidisc()`. A useful parameter
#' is `seed`, which is used to set the random number seed.
#'
#' @return A `tibble`.
#' @export
#'
#' @examples
#' gtc = readr::read_csv(system.file("extdata/gtc.csv", package = "localsp"))
#' gtc
#' distmat = as.matrix(dist(gtc[, c("X","Y")]))
#' gtc = gtc[, -c(1,2)]
#'
#' \dontest{
#' # The following code requires multi-core parallel computing; otherwise, it takes approximately 5 minutes to run:
#' lisp(GTC ~ ., data = gtc, threshold = 4.2349, distmat = distmat,
#'      discnum = 3:5, discmethod = "quantile", cores = 6)
#' }
lisp = \(formula, data, threshold, distmat, discvar = NULL, discnum = 3:8,
         discmethod = c("sd", "equal", "geometric", "quantile", "natural"),
         cores = 1, ...){
  doclust = FALSE
  if (cores > 1) {
    doclust = TRUE
    cl = parallel::makeCluster(cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
  }

  if (inherits(data,"sf")){
    data = sf::st_drop_geometry(data)
  }
  xname = sdsfun::formula_varname(formula, data)[[2]]
  resname = paste0(rep(c("pd","sig"),times = length(xname)), "_", rep(xname,each = 2))

  calcul_localq = \(rowindice,formula,df,bw,dm,discvar,discn,discm,...){
    localdf = df[which(dm[rowindice,] <= bw),]
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
    out_g = parallel::parLapply(cl,1:nrow(data),calcul_localq,formula,data,
                                threshold,distmat,discvar,discnum,discmethod,...)
    out_g = tibble::as_tibble(do.call(rbind, out_g))
  } else {
    out_g = purrr::map_dfr(1:nrow(data),calcul_localq,formula,data,threshold,
                           distmat,discvar,discnum,discmethod,...)
  }

  out_g = dplyr::arrange(out_g,rid)[,resname]
  return(out_g)
}
