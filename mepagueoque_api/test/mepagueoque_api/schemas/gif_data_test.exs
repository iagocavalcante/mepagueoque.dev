defmodule MepagueoqueApi.Schemas.GifDataTest do
  use ExUnit.Case, async: true

  alias MepagueoqueApi.Schemas.GifData

  describe "from_giphy_response/1" do
    test "creates GifData from valid Giphy response" do
      response = %{
        "data" => %{
          "url" => "https://giphy.com/gifs/money-123",
          "title" => "Money GIF",
          "images" => %{
            "original" => %{
              "url" => "https://media.giphy.com/media/123/giphy.gif",
              "width" => "480",
              "height" => "270"
            }
          }
        }
      }

      gif_data = GifData.from_giphy_response(response)

      assert gif_data.url == "https://giphy.com/gifs/money-123"
      assert gif_data.image_url == "https://media.giphy.com/media/123/giphy.gif"
      assert gif_data.image_width == "480"
      assert gif_data.image_height == "270"
      assert gif_data.title == "Money GIF"
    end

    test "handles missing optional fields" do
      response = %{
        "data" => %{
          "images" => %{
            "original" => %{
              "url" => "https://media.giphy.com/media/123/giphy.gif"
            }
          }
        }
      }

      gif_data = GifData.from_giphy_response(response)

      assert gif_data.image_url == "https://media.giphy.com/media/123/giphy.gif"
      assert gif_data.url == nil
      assert gif_data.image_width == nil
      assert gif_data.image_height == nil
      assert gif_data.title == nil
    end

    test "handles empty response" do
      response = %{}

      gif_data = GifData.from_giphy_response(response)

      assert gif_data.url == nil
      assert gif_data.image_url == nil
      assert gif_data.image_width == nil
      assert gif_data.image_height == nil
      assert gif_data.title == nil
    end
  end

  describe "valid?/1" do
    test "returns true for valid GIF data with image URL" do
      gif_data = %GifData{
        image_url: "https://media.giphy.com/media/123/giphy.gif",
        image_width: "480",
        image_height: "270"
      }

      assert GifData.valid?(gif_data)
    end

    test "returns false when image URL is nil" do
      gif_data = %GifData{
        image_url: nil,
        image_width: "480",
        image_height: "270"
      }

      refute GifData.valid?(gif_data)
    end

    test "returns false when image URL is empty string" do
      gif_data = %GifData{
        image_url: "",
        image_width: "480",
        image_height: "270"
      }

      refute GifData.valid?(gif_data)
    end

    test "returns true even when dimensions are missing" do
      gif_data = %GifData{
        image_url: "https://media.giphy.com/media/123/giphy.gif"
      }

      assert GifData.valid?(gif_data)
    end
  end
end
