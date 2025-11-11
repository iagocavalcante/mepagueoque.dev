defmodule MepagueoqueApi.Schemas.GifData do
  @moduledoc """
  Schema for GIF data from Giphy API.

  This module defines the structure for GIF metadata retrieved from Giphy.
  """

  @type t :: %__MODULE__{
          url: String.t() | nil,
          image_url: String.t() | nil,
          image_width: String.t() | nil,
          image_height: String.t() | nil,
          title: String.t() | nil
        }

  defstruct [:url, :image_url, :image_width, :image_height, :title]

  @doc """
  Creates a new GifData struct from Giphy API response.

  ## Parameters
    - data: Map containing GIF data from Giphy

  ## Returns
    - %GifData{} struct

  ## Examples

      iex> GifData.from_giphy_response(%{"data" => %{"url" => "https://giphy.com/gifs/...", "images" => %{"original" => %{"url" => "https://media.giphy.com/...", "width" => "480", "height" => "270"}}}})
      %GifData{url: "https://giphy.com/gifs/...", image_url: "https://media.giphy.com/...", image_width: "480", image_height: "270"}
  """
  @spec from_giphy_response(map()) :: t()
  def from_giphy_response(response) when is_map(response) do
    # Handle both string and atom keys
    data = response["data"] || response[:data]

    %__MODULE__{
      url: get_field(data, "url") || get_field(data, :url),
      image_url: get_image_field(data, "original", "url"),
      image_width: get_image_field(data, "original", "width"),
      image_height: get_image_field(data, "original", "height"),
      title: get_field(data, "title") || get_field(data, :title)
    }
  end

  defp get_field(nil, _key), do: nil
  defp get_field(map, key) when is_map(map), do: Map.get(map, key)
  defp get_field(_map, _key), do: nil

  defp get_image_field(nil, _image_type, _field), do: nil
  defp get_image_field(data, image_type, field) when is_map(data) do
    images = data["images"] || data[:images]
    original = if is_map(images), do: images[image_type] || images[String.to_atom(image_type)]
    if is_map(original), do: original[field] || original[String.to_atom(field)]
  end
  defp get_image_field(_data, _image_type, _field), do: nil

  @doc """
  Checks if the GIF data is valid (has required fields).

  ## Parameters
    - gif_data: %GifData{} struct

  ## Returns
    - true if image_url is present, false otherwise
  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{image_url: image_url}) when is_binary(image_url) and image_url != "",
    do: true

  def valid?(_), do: false
end
