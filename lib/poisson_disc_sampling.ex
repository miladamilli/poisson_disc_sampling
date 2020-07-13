defmodule PoissonDiscSampling do
  @moduledoc """
  Generating points using "Poisson disc sampling" algorithm.
  """

  # "min_dist" - minimal distance between samples (objects) [px]
  # "samples" - limit of samples to choose before rejection in the algorithm, typically 30

  # number of dimensions
  @dimensions 2

  def generate(canvas_w, canvas_h, min_dist, samples) do
    # size of grid cell
    cell_size = min_dist / :math.sqrt(@dimensions)

    random_point = {x, y} = {random_0_to_value(canvas_w), random_0_to_value(canvas_h)}

    # find where the point is in the grid and put in in the grid
    grid = Map.put(%{}, get_cell(x, y, cell_size), random_point)

    # and put it into list of active samples as well
    generate_points(grid, [random_point], cell_size, min_dist, samples, canvas_w, canvas_h)
    |> Map.values()
  end

  defp generate_points(grid, [], _, _, _, _, _) do
    grid
  end

  defp generate_points(
         grid,
         [point | active_points],
         cell_size,
         min_dist,
         samples,
         canvas_w,
         canvas_h
       ) do
    candidates = generate_active_points(point, [], samples, min_dist, canvas_w, canvas_h)

    {grid, active} = parse_active_points(grid, candidates, [], cell_size, min_dist)

    generate_points(
      grid,
      active_points ++ active,
      cell_size,
      min_dist,
      samples,
      canvas_w,
      canvas_h
    )
  end

  # TODO: Enum.map(0..samples, fn _ -> monte_carlo end)
  # |> Enum.filter(&in_canvas?(...))

  # TODO: Stream.repeatedly(fn -> :rand.uniform(10) end) |> Stream.filter(& &1 < 3) |> Enum.take(20)
  defp generate_active_points(_point, candidates, 0, _, _, _) do
    candidates
  end

  defp generate_active_points({x, y}, candidates, samples, min_dist, canvas_w, canvas_h) do
    # generate up to 'samples' points
    # pick a random point between 'min_dist' and '2*min_dist'
    {rand_x, rand_y} = monte_carlo(min_dist)
    new_candidate = {new_x, new_y} = {x + rand_x, y + rand_y}

    if in_canvas?(new_x, new_y, canvas_w, canvas_h) do
      generate_active_points(
        {x, y},
        [new_candidate | candidates],
        samples - 1,
        min_dist,
        canvas_w,
        canvas_h
      )
    else
      generate_active_points(
        {x, y},
        candidates,
        samples - 1,
        min_dist,
        canvas_w,
        canvas_h
      )
    end
  end

  defp parse_active_points(grid, [], candidates, _cell_size, _) do
    {grid, candidates}
  end

  defp parse_active_points(grid, [{x, y} = point | rest], candidates, cell_size, min_dist) do
    cell = get_cell(x, y, cell_size)

    if Map.has_key?(grid, cell) do
      parse_active_points(grid, rest, candidates, cell_size, min_dist)
    else
      if has_minimal_distance?(point, grid, cell_size, min_dist) do
        grid = Map.put(grid, cell, point)
        parse_active_points(grid, rest, [point | candidates], cell_size, min_dist)
      else
        parse_active_points(grid, rest, candidates, cell_size, min_dist)
      end
    end
  end

  defp has_minimal_distance?(point, grid, cell_size, min_dist) do
    # at first get points in neighbouring cells
    neighbour_points = neighbour_points(point, grid, cell_size)

    # check if neighbours are no closer than 'min_dist'
    Enum.all?(neighbour_points, &min_distance?(point, &1, min_dist))
  end

  defp min_distance?({x, y}, {nx, ny}, min_dist) do
    min_dist < :math.sqrt((nx - x) * (nx - x) + (ny - y) * (ny - y))
  end

  defp neighbour_points({x, y}, grid, cell_size) do
    {col, row} = get_cell(x, y, cell_size)

    # -1..1 could be enough, but there are some corner cases

    for i <- -2..2, j <- -2..2, point = grid[{col + i, row + j}], not is_nil(point) do
      point
    end
  end

  defp in_canvas?(x, y, canvas_w, canvas_h) do
    x >= 0 && x <= canvas_w && y >= 0 && y <= canvas_h
  end

  defp monte_carlo(min_dist) do
    max_dist = 2 * min_dist
    x = random_0_to_value(max_dist) * Enum.random([-1, 1])
    y = random_0_to_value(max_dist) * Enum.random([-1, 1])
    r = :math.sqrt(x * x + y * y)
    if r >= min_dist and r <= max_dist, do: {x, y}, else: monte_carlo(min_dist)
  end

  defp random_0_to_value(value) do
    :rand.uniform(value + 1) - 1
  end

  defp get_cell(x, y, cell_size) do
    {trunc(x / cell_size), trunc(y / cell_size)}
  end
end
