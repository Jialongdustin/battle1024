defmodule Battle.Utils.CheckGit do

  def is_valid?(git, tag) do
    is_valid_url?(git) && is_valid_tag?(git, tag)
  end

  defp is_valid_url?(git) do
    String.starts_with?(git, ["http://", "https://", "git@"])
  end

  defp is_valid_tag?(git, tag) do
    {output, status} = System.cmd("git", ["ls-remote", "--heads", git, tag])
    if status == 0 do
      String.contains?(output, "refs/heads/#{tag}")
    else
      false
    end
  end

end
