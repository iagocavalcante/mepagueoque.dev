defmodule MepagueoqueApi.Schemas.PaymentReminderTest do
  use ExUnit.Case, async: true

  alias MepagueoqueApi.Schemas.PaymentReminder

  describe "new/1" do
    test "creates valid PaymentReminder with string keys" do
      params = %{
        "text" => "Please pay me",
        "value" => "100.00",
        "destination" => "user@example.com",
        "token" => "abc123"
      }

      assert {:ok, %PaymentReminder{} = reminder} = PaymentReminder.new(params)
      assert reminder.text == "Please pay me"
      assert reminder.value == "100.00"
      assert reminder.destination == "user@example.com"
      assert reminder.token == "abc123"
    end

    test "creates valid PaymentReminder with atom keys" do
      params = %{
        text: "Please pay me",
        value: "100.00",
        destination: "user@example.com",
        token: "abc123"
      }

      assert {:ok, %PaymentReminder{} = reminder} = PaymentReminder.new(params)
      assert reminder.text == "Please pay me"
    end

    test "trims whitespace from inputs" do
      params = %{
        "text" => "  Please pay me  ",
        "value" => "  100.00  ",
        "destination" => "  user@example.com  ",
        "token" => "  abc123  "
      }

      assert {:ok, %PaymentReminder{} = reminder} = PaymentReminder.new(params)
      assert reminder.text == "Please pay me"
      assert reminder.value == "100.00"
      assert reminder.destination == "user@example.com"
      assert reminder.token == "abc123"
    end

    test "downcases email address" do
      params = %{
        "text" => "Pay me",
        "value" => "100",
        "destination" => "USER@EXAMPLE.COM",
        "token" => "token"
      }

      assert {:ok, %PaymentReminder{} = reminder} = PaymentReminder.new(params)
      assert reminder.destination == "user@example.com"
    end

    test "returns error when text is missing" do
      params = %{
        "value" => "100.00",
        "destination" => "user@example.com",
        "token" => "abc123"
      }

      assert {:error, :invalid_params, errors} = PaymentReminder.new(params)
      assert "text is required" in errors
    end

    test "returns error when value is missing" do
      params = %{
        "text" => "Please pay me",
        "destination" => "user@example.com",
        "token" => "abc123"
      }

      assert {:error, :invalid_params, errors} = PaymentReminder.new(params)
      assert "value is required" in errors
    end

    test "returns error when destination is missing" do
      params = %{
        "text" => "Please pay me",
        "value" => "100.00",
        "token" => "abc123"
      }

      assert {:error, :invalid_params, errors} = PaymentReminder.new(params)
      assert "destination is required" in errors
    end

    test "returns error when token is missing" do
      params = %{
        "text" => "Please pay me",
        "value" => "100.00",
        "destination" => "user@example.com"
      }

      assert {:error, :invalid_params, errors} = PaymentReminder.new(params)
      assert "token is required" in errors
    end

    test "returns error when text is empty string" do
      params = %{
        "text" => "",
        "value" => "100.00",
        "destination" => "user@example.com",
        "token" => "abc123"
      }

      assert {:error, :invalid_params, errors} = PaymentReminder.new(params)
      assert "text cannot be empty" in errors
    end

    test "returns error when text is only whitespace" do
      params = %{
        "text" => "   ",
        "value" => "100.00",
        "destination" => "user@example.com",
        "token" => "abc123"
      }

      assert {:error, :invalid_params, errors} = PaymentReminder.new(params)
      assert "text cannot be empty" in errors
    end

    test "returns multiple errors when multiple fields are invalid" do
      params = %{
        "text" => "",
        "value" => ""
      }

      assert {:error, :invalid_params, errors} = PaymentReminder.new(params)
      assert length(errors) == 4
      assert "text cannot be empty" in errors
      assert "value cannot be empty" in errors
      assert "destination is required" in errors
      assert "token is required" in errors
    end

    test "truncates text longer than 1000 characters" do
      long_text = String.duplicate("a", 1500)

      params = %{
        "text" => long_text,
        "value" => "100.00",
        "destination" => "user@example.com",
        "token" => "abc123"
      }

      assert {:ok, %PaymentReminder{} = reminder} = PaymentReminder.new(params)
      assert String.length(reminder.text) == 1000
    end

    test "truncates email longer than 254 characters" do
      long_email = String.duplicate("a", 300) <> "@example.com"

      params = %{
        "text" => "Pay me",
        "value" => "100.00",
        "destination" => long_email,
        "token" => "abc123"
      }

      assert {:ok, %PaymentReminder{} = reminder} = PaymentReminder.new(params)
      assert String.length(reminder.destination) == 254
    end
  end
end
