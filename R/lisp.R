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
#'
#' \donttest{
#' # Sample 100 observations from the original data to save runtime;
#' # This is unnecessary in practice;
#' set.seed(42)
#' gtc1 = gtc[sample.int(nrow(gtc),size = 100),]
#' distmat = as.matrix(dist(gtc1[, c("X","Y")]))
#' gtc1 = gtc1[, -c(1,2)]
#' gtc1
#'
#' # Use 2 cores for parallel computing;
#' # Increase cores in practice to speed up;
#' lisp(GTC ~ ., data = gtc1, threshold = 4.2349, distmat = distmat,
#'      discnum = 3:5, discmethod = "quantile", cores = 2)
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
                        discmethod = discm, cores = 1, type = "interaction", ...)$interaction
    qv1 = dplyr::select(res,c(1,4,7))
    qv2 = dplyr::select(res,c(2,5,8))
    names(qv1) = names(qv2) = c("variable","pd","sig")
    factor_qv = dplyr::bind_rows(qv1,qv2) |> 
      dplyr::distinct() |> 
      tidyr::pivot_longer(2:3,names_to = "qn",values_to = "qv") |> 
      tidyr::pivot_wider(names_from = 2:1, values_from = 3)
    interaction_qv
    tidyr::pivot_longer(dplyr::select(res,c(1,4,7)),2:3,names_to = "qn",values_to = "qv")->b
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

sim = gdverse::sim
gdverse::opgd(y ~ xa + xb + xc, data = sim,
              discvar = paste0('x',letters[1:3]),
              discnum = 3:6, type = "interaction") -> a
