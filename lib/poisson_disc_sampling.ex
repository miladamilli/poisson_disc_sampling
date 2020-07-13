defmodule PoissonDiscSampling do
  @moduledoc """
  Generates evenly randomly distributed points using "Poisson disc sampling" algorithm.
  """

  defstruct [:min_dist, :area_width, :area_height, :samples, :cell_size]

  @dimensions 2

  @doc """
  Returns list of points, each point is a two-element tuple `{x, y}`.

  Points are distributed in a rectangular area of dimensions
  `area_width` and `area_height` and are at least minimum distance `min_dist` apart.

  `Samples` is maximum number of attempts to find a new suitable point in each step
  (typically 30).
  """

  @spec generate(non_neg_integer, non_neg_integer, non_neg_integer, non_neg_integer) :: [
          {non_neg_integer, non_neg_integer}
        ]
  def generate(min_dist, area_width, area_height, samples) do
    opts = %PoissonDiscSampling{
      min_dist: min_dist,
      samples: samples,
      area_width: area_width,
      area_height: area_height,
      cell_size: min_dist / :math.sqrt(@dimensions)
    }

    random_point = {random(0, area_width), random(0, area_height)}

    generate_points([random_point], %{}, opts)
  end

  defp generate_points([], cells, _) do
    Map.values(cells)
  end

  defp generate_points([point | active_points], cells, opts) do
    new_active_points = generate_samples(point, opts)

    {cells, new_active_points} =
      process_new_active_points(new_active_points, cells, active_points, opts)

    generate_points(new_active_points, cells, opts)
  end

  defp generate_samples({x, y}, opts) do
    Enum.map(0..opts.samples, fn _ ->
      {rand_x, rand_y} = monte_carlo(opts.min_dist)
      {x + rand_x, y + rand_y}
    end)
  end

  defp process_new_active_points([], cells, active, _) do
    {cells, active}
  end

  defp process_new_active_points([point | points], cells, active, opts) do
    if inside_area?(point, opts.area_width, opts.area_height) &&
         has_min_distance?(point, cells, opts) do
      cell = get_cell(point, opts.cell_size)
      cells = Map.put(cells, cell, point)
      process_new_active_points(points, cells, [point | active], opts)
    else
      process_new_active_points(points, cells, active, opts)
    end
  end

  defp has_min_distance?(point, cells, opts) do
    neighbouring_points = neighbouring_points(point, cells, opts.cell_size)
    min_dist_from_neighbours?(point, neighbouring_points, opts.min_dist)
  end

  defp min_dist_from_neighbours?(point, neighbouring_points, min_dist) do
    Enum.all?(neighbouring_points, &min_distance?(point, &1, min_dist))
  end

  defp min_distance?({x, y}, {nx, ny}, min_dist) do
    min_dist < :math.sqrt((nx - x) * (nx - x) + (ny - y) * (ny - y))
  end

  defp neighbouring_points(point, cells, cell_size) do
    {col, row} = get_cell(point, cell_size)

    # -1..1 could be enough, but there are some corner cases
    for i <- -2..2, j <- -2..2, point = cells[{col + i, row + j}] do
      point
    end
  end

  defp inside_area?({x, y}, area_width, area_height) do
    x >= 0 && x <= area_width && y >= 0 && y <= area_height
  end

  defp monte_carlo(min_dist) do
    max_dist = 2 * min_dist
    {x, y} = random_point_around(min_dist)
    r = :math.sqrt(x * x + y * y)
    if r >= min_dist and r <= max_dist, do: {x, y}, else: monte_carlo(min_dist)
  end

  defp random_point_around(dist) do
    {random(0, dist) * Enum.random([-1, 1]), random(0, dist) * Enum.random([-1, 1])}
  end

  defp random(from, to) do
    :rand.uniform(to - from + 1) + from - 1
  end

  defp get_cell({x, y}, cell_size) do
    {trunc(x / cell_size), trunc(y / cell_size)}
  end
end
