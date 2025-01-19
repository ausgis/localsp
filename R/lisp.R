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

  calcul_localq = \(rowindice,formula,data,bw,discvar,discn,discm,...){
    localdf = data[which(distmat[rowindice,] <= bw),]
    res = gdverse::opgd(formula, data = localdf, discvar = discvar,
                        discnum = discn, discmethod = discm, ...)$factor
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
