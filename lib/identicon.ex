defmodule Identicon do
  @moduledoc """
  Documentation for `Identicon`.
  """

  @doc """
  Creates an consistent image based of sting input 

  ## Examples

      iex> Identicon.main("kevin")
      :ok

  """
  def main(input) do
    input
    |> hash_input
    |> prep_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  def save_image(image, filename) do
    File.write("#{filename}", image)
  end

  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each pixel_map, fn({start, stop}) -> 
      :egd.filledRectangle(image, start, stop, fill)
    end

    :egd.render(image)
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = input) do
    pixel_map =
      Enum.map(grid, fn {_sq, indx} ->
        # this is horizontal vertex
        horizontal = rem(indx, 5) * 50
        # this is vertical vertex
        vertical = div(indx, 5) * 50

        top_left = {horizontal, vertical}
        bottom_right = {horizontal + 50, vertical + 50}

        # :egd.filledRectangle(Image::egd_image(), P1::point(), P2::point(), Color::color())
        # where P1::point()  = top_left, P2::point() = bottom_right
        {top_left, bottom_right}
      end)

    %Identicon.Image{input | pixel_map: pixel_map}
  end

  def filter_odd_squares(%Identicon.Image{grid: grid} = input) do
    grid =
      Enum.filter(grid, fn {sq, _indx} ->
        rem(sq, 2) == 0
      end)

    %Identicon.Image{input | grid: grid}
  end

  def mirror_row([first, second | _] = row) do
    row ++ [second, first]
  end

  def build_grid(%Identicon.Image{hex: hex_list} = input) do
    grid =
      hex_list
      |> Enum.chunk_every(3, 3, :discard)
      |> Enum.map(&mirror_row/1)
      |> List.flatten()
      |> Enum.with_index()

    %Identicon.Image{input | grid: grid}
  end

  def prep_color(%Identicon.Image{hex: hex_list} = input) do
    [r, g, b | _] = hex_list

    %Identicon.Image{input | color: {r, g, b}}
  end

  def hash_input(input) do
    hex =
      :crypto.hash(:md5, input)
      |> :binary.bin_to_list()

    %Identicon.Image{hex: hex}
  end
end
