defmodule ProteinLoopWeb.RealtimeTankScene do
  @moduledoc """
  Accessible HTML shell for the state-driven Three.js tank simulation.
  """

  use ProteinLoopWeb, :html

  attr :id, :string, required: true
  attr :state, :map, required: true

  def realtime_tank_scene(assigns) do
    ammonia = number(assigns.state, "ammonia_mg_l")
    oxygen = number(assigns.state, "dissolved_oxygen_mg_l")
    health = health(assigns.state, ammonia, oxygen)

    assigns =
      assigns
      |> assign(:ammonia, ammonia)
      |> assign(:oxygen, oxygen)
      |> assign(:day, whole_number(assigns.state, "day"))
      |> assign(:fish_biomass, number(assigns.state, "fish_biomass_kg"))
      |> assign(:prawn_biomass, number(assigns.state, "prawn_biomass_kg"))
      |> assign(:plant_biomass, number(assigns.state, "plant_biomass_kg"))
      |> assign(:duckweed, number(assigns.state, "duckweed_kg"))
      |> assign(:last_event, Map.get(assigns.state, "last_event", "live update"))
      |> assign(:health, health)
      |> assign(:ammonia_label, ammonia_label(ammonia))
      |> assign(:oxygen_label, oxygen_label(oxygen))

    ~H"""
    <section
      id={@id}
      phx-hook="RealtimeTank"
      class="realtime-tank -mx-4 overflow-hidden border-y border-base-300 sm:-mx-6 lg:mx-0"
      data-day={@day}
      data-ammonia={@ammonia}
      data-oxygen={@oxygen}
      data-fish-biomass={@fish_biomass}
      data-prawn-biomass={@prawn_biomass}
      data-plant-biomass={@plant_biomass}
      data-duckweed={@duckweed}
      data-health={@health.key}
      data-collapsed={Map.get(@state, "collapsed", false)}
      data-last-event={@last_event}
    >
      <div
        class="realtime-tank__viewport"
        role="img"
        aria-label={
          "Animated fish and freshwater prawn tank. #{@health.heading}. Ammonia #{@ammonia} milligrams per liter and dissolved oxygen #{@oxygen} milligrams per liter."
        }
      >
        <div id={"#{@id}-webgl"} phx-update="ignore" class="realtime-tank__render-layer">
          <img
            data-tank-fallback
            src={~p"/images/protein-loop-system.svg"}
            alt="Illustration fallback of the fish and prawn tank connected to the protein loop"
            class="realtime-tank__fallback"
          />
          <canvas data-tank-canvas class="realtime-tank__canvas" aria-hidden="true"></canvas>
        </div>

        <div class="realtime-tank__heading">
          <div class="flex items-center gap-2">
            <span class="realtime-tank__live-dot" aria-hidden="true"></span>
            <p class="text-xs font-semibold uppercase tracking-wide text-info">
              Live tank simulation
            </p>
            <span class="text-xs text-base-content/55">Day {@day}</span>
          </div>
          <h2 class="mt-1 text-xl font-semibold sm:text-2xl">Main fish & prawn tank</h2>
          <p class="mt-1 max-w-xl text-sm font-medium text-base-content/75">{@health.heading}</p>
        </div>

        <div class="realtime-tank__commands">
          <button class="btn btn-sm btn-error" phx-click="spike">
            <.icon name="hero-bolt" /> Simulate water emergency
          </button>
          <button
            class="btn btn-square btn-sm btn-outline bg-white"
            phx-click="reset"
            title="Reset tank"
          >
            <.icon name="hero-arrow-uturn-left" />
            <span class="sr-only">Reset tank</span>
          </button>
        </div>

        <div class="realtime-tank__hud">
          <div class="realtime-tank__condition">
            <span class={["badge badge-sm", @health.badge_class]}>{@health.badge}</span>
            <p class="mt-1 text-sm font-semibold">{@health.summary}</p>
            <p class="mt-1 truncate text-xs text-base-content/55">Latest: {@last_event}</p>
          </div>

          <dl class="realtime-tank__metrics">
            <div>
              <dt>Waste in water</dt>
              <dd class={@health.ammonia_class}>{@ammonia} mg/L</dd>
              <p>Ammonia · {@ammonia_label}</p>
            </div>
            <div>
              <dt>Breathing oxygen</dt>
              <dd class={@health.oxygen_class}>{@oxygen} mg/L</dd>
              <p>Dissolved oxygen · {@oxygen_label}</p>
            </div>
            <div>
              <dt>Living protein</dt>
              <dd>{@fish_biomass} kg</dd>
              <p>Fish · {@prawn_biomass} kg prawns</p>
            </div>
            <div>
              <dt>Plant loop</dt>
              <dd>{@plant_biomass} kg</dd>
              <p>Plants · {@duckweed} kg duckweed</p>
            </div>
          </dl>
        </div>
      </div>
    </section>
    """
  end

  defp health(state, ammonia, oxygen) do
    cond do
      Map.get(state, "collapsed", false) or ammonia >= 3.0 or oxygen < 3.5 ->
        %{
          key: "critical",
          badge: "Immediate action",
          badge_class: "badge-error",
          ammonia_class: "text-error",
          oxygen_class: "text-error",
          heading: "Tank animals are in danger",
          summary: "Waste is dangerous or the animals cannot breathe comfortably."
        }

      ammonia >= 1.5 or oxygen < 5.0 ->
        %{
          key: "warning",
          badge: "Needs attention",
          badge_class: "badge-warning",
          ammonia_class: "text-warning",
          oxygen_class: "text-warning",
          heading: "The tank is starting to struggle",
          summary: "Waste is rising or oxygen is falling outside the comfortable range."
        }

      true ->
        %{
          key: "stable",
          badge: "Healthy",
          badge_class: "badge-success",
          ammonia_class: "text-success",
          oxygen_class: "text-info",
          heading: "Fish and prawns are active",
          summary: "Water conditions support normal feeding, breathing, and movement."
        }
    end
  end

  defp ammonia_label(value) when value >= 3.0, do: "Dangerous waste"
  defp ammonia_label(value) when value >= 1.5, do: "Waste rising"
  defp ammonia_label(_value), do: "Safe"

  defp oxygen_label(value) when value < 3.5, do: "Low oxygen"
  defp oxygen_label(value) when value < 5.0, do: "Oxygen falling"
  defp oxygen_label(_value), do: "Comfortable"

  defp number(map, key) do
    case Map.get(map, key, 0) do
      value when is_integer(value) -> value * 1.0
      value when is_float(value) -> Float.round(value, 2)
      _other -> 0.0
    end
  end

  defp whole_number(map, key) do
    case Map.get(map, key, 0) do
      value when is_integer(value) -> value
      value when is_float(value) -> round(value)
      _other -> 0
    end
  end
end
