defmodule PoissonDiscSampling do
  @moduledoc """
  Generating evenly randomly distributed points using "Poisson disc sampling" algorithm.
  """

  @dimensions 2

  def generate(canvas_w, canvas_h, min_dist, samples) do
    cell_size = min_dist / :math.sqrt(@dimensions)
    random_point = {random(0, canvas_w), random(0, canvas_h)}
    cells = Map.put(%{}, get_cell(random_point, cell_size), random_point)

    generate_points(cells, [random_point], cell_size, min_dist, samples, canvas_w, canvas_h)
  end

  defp generate_points(cells, [], _, _, _, _, _) do
    cells |> Map.values()
  end

  defp generate_points(
         cells,
         [point | active_points],
         cell_size,
         min_dist,
         samples,
         canvas_w,
         canvas_h
       ) do
    active_candidates = generate_samples(point, samples, min_dist, canvas_w, canvas_h)

    {cells, active} = process_active_points(cells, active_candidates, [], cell_size, min_dist)

    generate_points(
      cells,
      active_points ++ active,
      cell_size,
      min_dist,
      samples,
      canvas_w,
      canvas_h
    )
  end

  defp generate_samples({x, y}, samples, min_dist, canvas_w, canvas_h) do
    Enum.map(0..samples, fn _ ->
      {rand_x, rand_y} = monte_carlo(min_dist)
      {x + rand_x, y + rand_y}
    end)
    |> Enum.filter(&in_canvas?(&1, canvas_w, canvas_h))
  end

  defp process_active_points(cells, [], active, _, _) do
    {cells, active}
  end

  defp process_active_points(cells, [point | points], active, cell_size, min_dist) do
    if has_minimal_distance?(point, cells, cell_size, min_dist) do
      cell = get_cell(point, cell_size)
      cells = Map.put(cells, cell, point)
      process_active_points(cells, points, [point | active], cell_size, min_dist)
    else
      process_active_points(cells, points, active, cell_size, min_dist)
    end
  end

  defp has_minimal_distance?(point, cells, cell_size, min_dist) do
    neighbouring_points = neighbour_points(point, cells, cell_size)
    min_dist_from_neighbours?(point, neighbouring_points, min_dist)
  end

  defp min_dist_from_neighbours?(point, neighbouring_points, min_dist) do
    Enum.all?(neighbouring_points, &min_distance?(point, &1, min_dist))
  end

  defp min_distance?({x, y}, {nx, ny}, min_dist) do
    min_dist < :math.sqrt((nx - x) * (nx - x) + (ny - y) * (ny - y))
  end

  defp neighbour_points(point, cells, cell_size) do
    {col, row} = get_cell(point, cell_size)

    # -1..1 could be enough, but there are some corner cases
    for i <- -2..2, j <- -2..2, point = cells[{col + i, row + j}], not is_nil(point) do
      point
    end
  end

  defp in_canvas?({x, y}, canvas_w, canvas_h) do
    x >= 0 && x <= canvas_w && y >= 0 && y <= canvas_h
  end

  defp monte_carlo(min_dist) do
    max_dist = 2 * min_dist
    x = random(0, max_dist) * Enum.random([-1, 1])
    y = random(0, max_dist) * Enum.random([-1, 1])
    r = :math.sqrt(x * x + y * y)
    if r >= min_dist and r <= max_dist, do: {x, y}, else: monte_carlo(min_dist)
  end

  defp random(from, to) do
    :rand.uniform(to - from + 1) + from - 1
  end

  defp get_cell({x, y}, cell_size) do
    {trunc(x / cell_size), trunc(y / cell_size)}
  end
end
