defmodule PoissonDiscSampling do
  @moduledoc """
  Documentation for `PoissonDiscSampling`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> PoissonDiscSampling.hello()
      :world

  """

  # "min_dist" - minimal distance between samples (objects) [px]
  # "samples" - limit of samples to choose before rejection in the algorithm, typically 30

  # number of dimensions
  @dimensions 2

  def generate(canvas_w, canvas_h, min_dist, samples) do
    grid(canvas_w, canvas_h, min_dist, samples)
  end

  defp grid(canvas_w, canvas_h, min_dist, samples) do
    # size of grid cell
    cell_size = min_dist / :math.sqrt(@dimensions)

    # pick a random point {x,y}
    random_point = {x, y} = {Enum.random(0..canvas_w), Enum.random(0..canvas_h)}

    # find where the point is in the grid and put in in the grid
    grid = Map.put(%{}, {trunc(x / cell_size), trunc(y / cell_size)}, random_point)

    # and put it into list of active samples as well
    generate_points(grid, [random_point], cell_size, min_dist, samples, canvas_w, canvas_h)
  end

  defp generate_points(grid, [], _cell_size, _, _, _, _) do
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
    # check if points are within 'min_dist' distance
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

  defp parse_active_points(grid, [], active, _cell_size, _) do
    {grid, active}
  end

  defp parse_active_points(grid, [{x, y} = point | rest], active, cell_size, min_dist) do
    if grid[{trunc(x / cell_size), trunc(y / cell_size)}] == nil do
      if check_within_distance(point, grid, cell_size, min_dist) do
        grid = Map.put(grid, {trunc(x / cell_size), trunc(y / cell_size)}, point)

        parse_active_points(grid, rest, [point | active], cell_size, min_dist)
      else
        parse_active_points(grid, rest, active, cell_size, min_dist)
      end
    else
      parse_active_points(grid, rest, active, cell_size, min_dist)
    end
  end

  defp generate_active_points(_point, active, 0, _, _, _) do
    active
  end

  defp generate_active_points({x, y}, active, samples, min_dist, canvas_w, canvas_h) do
    # generate up to 'samples' points
    # pick a random point distant between 'min_dist' and '2*min_dist'
    {rand_x, rand_y} = monte_carlo(min_dist)
    new_active_point = {new_x, new_y} = {x + rand_x, y + rand_y}

    if new_x >= 0 && new_x <= canvas_w && new_y >= 0 && new_y <= canvas_h do
      generate_active_points(
        {x, y},
        [new_active_point | active],
        samples - 1,
        min_dist,
        canvas_w,
        canvas_h
      )
    else
      generate_active_points(
        {x, y},
        active,
        samples - 1,
        min_dist,
        canvas_w,
        canvas_h
      )
    end
  end

  defp check_within_distance(point, grid, cell_size, min_dist) do
    # at first get points in neighbouring cells
    neighbour_points = neighbour_points(point, grid, cell_size)

    # check if points are within 'min_dist' distance
    distance_check =
      Enum.map(neighbour_points, fn neighbour -> check_distance(point, neighbour, min_dist) end)

    false not in distance_check
  end

  defp check_distance({x, y}, {nx, ny}, min_dist) do
    # check if point is within 'min_dist' distance from neighbours
    min_dist < :math.sqrt((nx - x) * (nx - x) + (ny - y) * (ny - y))
  end

  defp neighbour_points({x, y}, grid, cell_size) do
    col = trunc(x / cell_size)
    row = trunc(y / cell_size)

    # -1..1 could be enough, but there are some corner cases
    neighbour_cells = for i <- -2..2, j <- -2..2, do: {col + i, row + j}

    Enum.filter(grid, fn {cell, _point} -> cell in neighbour_cells end)
    |> Enum.map(fn {_cell, point} -> point end)
  end

  defp monte_carlo(min_dist) do
    max_dist = 2 * min_dist
    x = (:rand.uniform(max_dist + 1) - 1) * Enum.random([-1, 1])
    y = (:rand.uniform(max_dist + 1) - 1) * Enum.random([-1, 1])
    r = :math.sqrt(x * x + y * y)
    if r >= min_dist and r <= max_dist, do: {x, y}, else: monte_carlo(min_dist)
  end
end
