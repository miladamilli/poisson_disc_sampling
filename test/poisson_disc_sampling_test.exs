defmodule PoissonDiscSamplingTest do
  use ExUnit.Case
  doctest PoissonDiscSampling

  test "all points are minimum distance apart" do
    min_dist = 47
    points = PoissonDiscSampling.generate(min_dist, 1731, 997, 27)

    for {ax, ay} = a <- points, {bx, by} = b <- points, a != b do
      assert :math.sqrt(:math.pow(ax - bx, 2) + :math.pow(ay - by, 2)) >= min_dist
    end
  end

  test "most of all the possible points are generated" do
    min_dist = 17
    w = 331
    h = 157
    points = PoissonDiscSampling.generate(min_dist, w, h, 30)
    all_points = for x <- 0..w, y <- 0..h, do: {x, y}

    evil_points =
      Enum.reject(all_points, fn {ax, ay} ->
        Enum.any?(points, fn {px, py} ->
          :math.sqrt(:math.pow(px - ax, 2) + :math.pow(py - ay, 2)) < min_dist
        end)
      end)

    cell_size = min_dist / :math.sqrt(2)

    evil_cells_count =
      Enum.count(
        Map.keys(
          Enum.group_by(evil_points, fn {x, y} -> {trunc(x / cell_size), trunc(y / cell_size)} end)
        )
      )

    total_cells_count = trunc((w + 1) / cell_size) * trunc((h + 1) / cell_size)

    # percent
    assert evil_cells_count / (total_cells_count / 100) < 4
  end
end
