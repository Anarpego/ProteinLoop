defmodule ProteinLoopWeb.RealtimeTankScene do
  @moduledoc """
  Accessible HTML shell for the state-driven Three.js tank simulation.
  """

  use ProteinLoopWeb, :html

  attr :id, :string, required: true
  attr :state, :map, required: true
  attr :controls, :boolean, default: false
  slot :agent_controls

  def realtime_tank_scene(assigns) do
    ammonia = number(assigns.state, "ammonia_mg_l")
    oxygen = number(assigns.state, "dissolved_oxygen_mg_l")
    fish_biomass = number(assigns.state, "fish_biomass_kg")
    prawn_biomass = number(assigns.state, "prawn_biomass_kg")
    aquatic_biomass = Float.round(fish_biomass + prawn_biomass, 2)
    health = health(assigns.state, ammonia, oxygen)

    assigns =
      assigns
      |> assign(:ammonia, ammonia)
      |> assign(:oxygen, oxygen)
      |> assign(:day, whole_number(assigns.state, "day"))
      |> assign(:fish_biomass, fish_biomass)
      |> assign(:prawn_biomass, prawn_biomass)
      |> assign(:aquatic_biomass, aquatic_biomass)
      |> assign(:plant_biomass, number(assigns.state, "plant_biomass_kg"))
      |> assign(:duckweed, number(assigns.state, "duckweed_kg"))
      |> assign(:chickens, whole_number(assigns.state, "chicken_count"))
      |> assign(:eggs, number(assigns.state, "eggs_count"))
      |> assign(:last_event, Map.get(assigns.state, "last_event", "live update"))
      |> assign(:health, health)
      |> assign(:protection_message, protection_message(health.key, aquatic_biomass))
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
      data-aquatic-biomass={@aquatic_biomass}
      data-plant-biomass={@plant_biomass}
      data-duckweed={@duckweed}
      data-chickens={@chickens}
      data-eggs={@eggs}
      data-health={@health.key}
      data-collapsed={Map.get(@state, "collapsed", false)}
      data-last-event={@last_event}
      data-fish-model-url={~p"/models/barramundi-fish.glb"}
      data-prawn-texture-url={~p"/models/greasyback-shrimp.jpeg"}
    >
      <div class="realtime-tank__viewport">
        <p id={"#{@id}-description"} class="sr-only">
          Animated fish and freshwater prawn tank with {@aquatic_biomass} kilograms of live animal
          biomass connected to plants, duckweed feed, {@chickens} hens, and {@eggs} tracked eggs. {@health.heading}. Ammonia {@ammonia} milligrams per liter and dissolved oxygen {@oxygen} milligrams per liter.
        </p>
        <div
          id={"#{@id}-webgl"}
          phx-update="ignore"
          class="realtime-tank__render-layer"
          role="img"
          aria-labelledby={"#{@id}-description"}
        >
          <div
            data-tank-fallback
            class="realtime-tank__fallback"
            aria-hidden="true"
          >
            <span class="realtime-tank__fallback-water"></span>
            <span class="realtime-tank__fallback-floor"></span>
          </div>
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
          <h2 class="mt-1 text-lg font-semibold sm:text-xl">Main fish & prawn tank</h2>
          <p class="mt-1 max-w-xl text-xs font-medium text-base-content/75 sm:text-sm">
            {@health.heading}
          </p>
          <p class="realtime-tank__stock-line">
            <.icon name="hero-scale" />
            <span>{@aquatic_biomass} kg fish + prawn stock</span>
          </p>
        </div>

        <div class="realtime-tank__commands">
          <span :if={@controls} class="realtime-tank__demo-badge">Demo mode</span>
          <button :if={@controls} class="btn btn-sm btn-error" phx-click="spike">
            <.icon name="hero-bolt" /> Inject demo water emergency
          </button>
          <button
            :if={@controls}
            class="btn btn-square btn-sm btn-outline bg-white"
            phx-click="reset"
            title="Reset tank"
          >
            <.icon name="hero-arrow-uturn-left" />
            <span class="sr-only">Reset tank</span>
          </button>
          <button
            id={"#{@id}-fullscreen"}
            type="button"
            class="btn btn-square btn-sm btn-outline bg-white"
            data-tank-fullscreen
            aria-label="Open tank full screen"
            aria-pressed="false"
            title="Open tank full screen"
          >
            <.icon name="hero-arrows-pointing-out" class="realtime-tank__fullscreen-open" />
            <.icon name="hero-arrows-pointing-in" class="realtime-tank__fullscreen-close" />
          </button>
        </div>

        <aside
          :if={@agent_controls != []}
          id="tank-agent-console"
          class="realtime-tank__agent-console"
        >
          {render_slot(@agent_controls)}
        </aside>

        <div class="realtime-tank__hud">
          <div class="realtime-tank__condition">
            <span class={["badge badge-sm", @health.badge_class]}>{@health.badge}</span>
            <p class="mt-1 text-sm font-semibold">{@health.summary}</p>
            <p class="mt-1 text-xs font-semibold text-base-content/70">{@protection_message}</p>
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
              <dt>Fish + prawn stock</dt>
              <dd>{@aquatic_biomass} kg</dd>
              <p>{@fish_biomass} kg fish · {@prawn_biomass} kg prawns</p>
            </div>
            <div>
              <dt>Plants → feed → eggs</dt>
              <dd>{@plant_biomass} kg plants</dd>
              <p>{@duckweed} kg duckweed · {@chickens} hens · {@eggs} eggs</p>
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

  defp protection_message("critical", biomass) do
    "#{biomass} kg of fish and prawns depend on this recovery."
  end

  defp protection_message("warning", biomass) do
    "#{biomass} kg of fish and prawns need protection as chemistry shifts."
  end

  defp protection_message(_health, biomass) do
    "#{biomass} kg of fish and prawns are supported by this water loop."
  end

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
