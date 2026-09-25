defmodule PipeRacerWeb.HealthControllerTest do
  use PipeRacerWeb.ConnCase, async: true

  test "GET /health answers ok", %{conn: conn} do
    assert conn |> get("/health") |> text_response(200) == "ok"
  end
end
