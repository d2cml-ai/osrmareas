#' Get Ameba Area
#'
#' Create the concave area
#' @param routes_df_xy A data frame containing route information with x and y coordinates.
#' @param max_km The maximum distance threshold in kilometers for including routes in the area.
#' @param concavity The concavity parameter for the concaveman algorithm.
#' @param len_th The length threshold parameter for the concaveman algorithm.
#'
#' @return  A sf object representing the concave hull area.
#' @export
#'
#' @examples
get_area <- function(routes_df_xy, max_km, crs_ = sf::st_crs(routes_df_xy), concavity = 2, len_th = 0){
  border <-
    routes_df_xy |>
    dplyr::filter(distance < max_km) |>
    sf::st_drop_geometry() |>
    tibble::as_tibble() |>
    sf::st_as_sf(coords = c('x', 'y'), crs = crs_) |>
    concaveman::concaveman(concavity = concavity, length_threshold = len_th)
  return(border)
}

