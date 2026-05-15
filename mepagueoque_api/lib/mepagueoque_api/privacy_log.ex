defmodule MepagueoqueApi.PrivacyLog do
  @moduledoc """
  Helpers for keeping personal data out of application logs (LGPD Art. 46).

  Currently:
    * `mask_ip/1` keeps only the network portion of an IPv4 address (first
      three octets), replacing the host portion with `.x`. Useful for
      operational logs without making the user individually identifiable.
  """

  @spec mask_ip(String.t() | nil) :: String.t() | nil
  def mask_ip(nil), do: nil

  def mask_ip(ip) when is_binary(ip) do
    case String.split(ip, ".") do
      [a, b, c, _d] -> Enum.join([a, b, c, "x"], ".")
      _ -> "[masked]"
    end
  end

  def mask_ip(_), do: nil
end
