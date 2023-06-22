#' Get Routes Inside
#'
#' Calculates routes inside a
#' specified radius around a given latitude
#' and longitude point. It divides the area
#' into a grid of smaller polygons and computes the routes from the initial point to the centroids of each grid cell within the radius.
#'
#'
#' @param lat The latitude of the initial point.
#' @param lon The longitude of the initial point.
#' @param radius_km The radius in kilometers to define the area within which the routes are calculated. Default is 5 kilometers.
#' @param grid_size The size of the grid cells in kilometers. Default is 1 kilometer.
#' @param max_km The maximum distance in kilometers allowed for the routes. If specified, routes beyond this distance will be filtered out. Default is NULL (no maximum distance).
#' @param crs_ The coordinate reference system (CRS) code to use. Default is 4326 (WGS84).
#' @param f_grid The function to round up the number of grid cells. Default is ceiling.
#' @param .progress Logical value indicating whether to display a progress bar. Default is TRUE.
#'
#' @return  A spatial data frame containing the routes inside the specified radius.
#'
#' @examples
#' get_routes_inside(lat = -12.0464, lon = -77.0428, radius_km = 5)
#' @export
get_routes_inside <- function(
    lat, lon, radius_km = 5, grid_size = 1, max_km = NULL, crs_ = 4326, f_grid = ceiling, .progress = T) {

  initial_center <- c(lon, lat)
  n_grid <- f_grid(radius_km / grid_size)  * 2

  center <- initial_center |>
    sf::st_point() |>
    sf::st_sfc(crs = crs_) |>
    sf::st_buffer(radius_km * 1000, endCapStyle = "SQUARE") |>
    sf::st_cast('MULTIPOLYGON')

  grids <- sf::st_make_grid(center, n = n_grid) |>
    sf::st_as_sf() |>
    dplyr::rename(geometry = x)

  center_grid <- PeruData::get_centroid(grids) |>
    sf::st_drop_geometry() |>
    tibble::as_tibble()

  centrodie_grid <- center_grid |>
    sf::st_as_sf(coords = c('x_center', 'y_center'), remove = F, crs = crs_)

  destiny <- centrodie_grid |> dplyr::pull(geometry)

  get_route <- function(row_){
    destiny_i <- destiny[row_]
    dist_df <- osrm::osrmRoute(initial_center, destiny_i) |>
      dplyr::select(!c(src, dst))
    return(dist_df)
  }

  route_df <-
    purrr::map_df(1:nrow(center_grid), get_route, .progress = T)

  routes_df_final_coordinates <-
    route_df |>
    dplyr::bind_cols(center_grid) |>
    dplyr::rename(x = x_center, y = y_center) |>
    dplyr::mutate(x_origin = initial_center[1], y_origin = initial_center[2]) |>
    sf::st_as_sf()

  if(!is.null(max_km)){
    routes_df_final_coordinates <-
      routes_df_final_coordinates |>
      dplyr::filter(distance < max_km)
  }
  return(routes_df_final_coordinates)
}
