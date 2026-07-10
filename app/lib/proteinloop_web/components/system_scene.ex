defmodule ProteinLoopWeb.SystemScene do
  @moduledoc """
  Plain-language visual summary of the living ProteinLoop system.
  """

  use ProteinLoopWeb, :html

  attr :id, :string, required: true
  attr :state, :map, required: true

  def system_scene(assigns) do
    ammonia = number(assigns.state, "ammonia_mg_l")
    oxygen = number(assigns.state, "dissolved_oxygen_mg_l")

    assigns =
      assigns
      |> assign(:ammonia, ammonia)
      |> assign(:oxygen, oxygen)
      |> assign(:health, system_health(assigns.state, ammonia, oxygen))
      |> assign(:ammonia_status, ammonia_status(ammonia))
      |> assign(:oxygen_status, oxygen_status(oxygen))
      |> assign(:ammonia_percent, gauge_percent(ammonia, 4.5))
      |> assign(:oxygen_percent, gauge_percent(oxygen, 8.0))

    ~H"""
    <section id={@id} class="overflow-hidden rounded-box border border-base-300 bg-base-100">
      <header class="flex flex-col gap-3 border-b border-base-300 px-4 py-4 sm:flex-row sm:items-start sm:justify-between sm:px-5">
        <div>
          <p class="text-xs font-semibold uppercase tracking-wide text-secondary">Living system</p>
          <h2 class="mt-1 text-xl font-semibold">Your protein loop at a glance</h2>
          <p class="mt-1 max-w-3xl text-sm text-base-content/65">
            Water connects the animals, plants, duckweed, and chickens. The main tank is the first
            place to check when the system asks for help.
          </p>
        </div>
        <span class={["badge whitespace-nowrap", @health.badge_class]}>{@health.badge}</span>
      </header>

      <div class="grid lg:grid-cols-[1.3fr_0.7fr]">
        <div class="relative min-h-64 border-base-300 bg-[#f7fbfc] lg:border-r">
          <img
            src={~p"/images/protein-loop-system.svg"}
            alt="Illustration of the fish and prawn tank connected to hydroponic plants, duckweed, and chickens"
            class="h-full min-h-64 w-full object-contain p-3 sm:p-5"
          />
          <div class="absolute bottom-3 left-3 border-l-4 border-info bg-white/95 px-3 py-2 shadow-sm sm:bottom-5 sm:left-5">
            <p class="text-xs text-base-content/60">Main water home</p>
            <p class="text-sm font-semibold">Main fish & prawn tank</p>
            <p class="text-xs text-base-content/60">
              {rounded(number(@state, "fish_biomass_kg"))} kg fish · {rounded(
                number(@state, "prawn_biomass_kg")
              )} kg prawns
            </p>
          </div>
        </div>

        <div class="flex flex-col px-4 py-4 sm:px-5">
          <div class="border-l-4 border-base-content pl-3">
            <p class="text-xs text-base-content/60">What this means now</p>
            <p class="mt-1 text-lg font-semibold">{@health.heading}</p>
            <p class="mt-1 text-sm text-base-content/70">{@health.summary}</p>
          </div>

          <div class="mt-4 divide-y divide-base-300 border-y border-base-300">
            <article class="py-3">
              <div class="flex items-start justify-between gap-3">
                <div>
                  <p class="font-semibold">Waste in the water</p>
                  <p class="text-xs text-base-content/60">
                    Ammonia {@ammonia} mg/L · safe below 1.5
                  </p>
                </div>
                <span class={["badge badge-sm", @ammonia_status.badge_class]}>
                  {@ammonia_status.label}
                </span>
              </div>
              <div
                class="mt-2 h-2 w-full overflow-hidden rounded bg-base-300"
                role="progressbar"
                aria-label="Ammonia level"
                aria-valuenow={@ammonia}
                aria-valuemin="0"
                aria-valuemax="4.5"
              >
                <div
                  class={["h-full", @ammonia_status.bar_class]}
                  style={"width: #{@ammonia_percent}%"}
                >
                </div>
              </div>
              <p class="mt-2 text-xs text-base-content/65">
                Ammonia comes from animal waste and uneaten feed. Too much can damage gills.
              </p>
            </article>

            <article class="py-3">
              <div class="flex items-start justify-between gap-3">
                <div>
                  <p class="font-semibold">Air the animals can breathe</p>
                  <p class="text-xs text-base-content/60">
                    Dissolved oxygen {@oxygen} mg/L · comfortable above 5.0
                  </p>
                </div>
                <span class={["badge badge-sm", @oxygen_status.badge_class]}>
                  {@oxygen_status.label}
                </span>
              </div>
              <div
                class="mt-2 h-2 w-full overflow-hidden rounded bg-base-300"
                role="progressbar"
                aria-label="Dissolved oxygen level"
                aria-valuenow={@oxygen}
                aria-valuemin="0"
                aria-valuemax="8"
              >
                <div
                  class={["h-full", @oxygen_status.bar_class]}
                  style={"width: #{@oxygen_percent}%"}
                >
                </div>
              </div>
              <p class="mt-2 text-xs text-base-content/65">
                Dissolved oxygen is the usable air underwater. Low oxygen makes fish and prawns
                struggle to breathe.
              </p>
            </article>
          </div>

          <div class="mt-auto pt-4">
            <p class="text-xs text-base-content/60">Immediate priority</p>
            <p class="mt-1 text-sm font-semibold">{@health.priority}</p>
          </div>
        </div>
      </div>

      <div class="grid border-t border-base-300 sm:grid-cols-3">
        <div class="flex items-start gap-3 border-base-300 p-4 sm:border-r">
          <.icon name="hero-sun" class="mt-0.5 size-5 shrink-0 text-success" />
          <div>
            <p class="text-sm font-semibold">Hydroponic plants</p>
            <p class="text-xs text-base-content/60">
              Use nutrients from the tank · {rounded(number(@state, "plant_biomass_kg"))} kg
            </p>
          </div>
        </div>
        <div class="flex items-start gap-3 border-y border-base-300 p-4 sm:border-y-0 sm:border-r">
          <.icon name="hero-squares-plus" class="mt-0.5 size-5 shrink-0 text-info" />
          <div>
            <p class="text-sm font-semibold">Duckweed reserve</p>
            <p class="text-xs text-base-content/60">
              Stores feed protein · {rounded(number(@state, "duckweed_kg"))} kg available
            </p>
          </div>
        </div>
        <div class="flex items-start gap-3 p-4">
          <.icon name="hero-home-modern" class="mt-0.5 size-5 shrink-0 text-warning" />
          <div>
            <p class="text-sm font-semibold">Chicken & egg output</p>
            <p class="text-xs text-base-content/60">
              {round(number(@state, "chicken_count"))} chickens · {rounded(
                number(@state, "eggs_count")
              )} eggs
            </p>
          </div>
        </div>
      </div>
    </section>
    """
  end

  defp system_health(state, ammonia, oxygen) do
    cond do
      Map.get(state, "collapsed", false) or ammonia >= 3.0 or oxygen < 3.5 ->
        %{
          badge: "Immediate action",
          badge_class: "badge-error",
          heading: "Tank animals are in danger",
          summary: "Waste is dangerous or breathing oxygen is critically low.",
          priority: "Stop feeding, maximize aeration, and verify a partial water change."
        }

      ammonia >= 1.5 or oxygen < 5.0 ->
        %{
          badge: "Needs attention",
          badge_class: "badge-warning",
          heading: "The main tank needs attention",
          summary: "Waste is building up or the animals need more breathing oxygen.",
          priority: "Reduce feed, increase aeration, and monitor the next reading."
        }

      true ->
        %{
          badge: "Healthy",
          badge_class: "badge-success",
          heading: "Tank animals can feed and breathe normally",
          summary: "Waste and underwater oxygen are inside the comfortable operating range.",
          priority: "Continue the normal routine and watch for changes."
        }
    end
  end

  defp ammonia_status(value) when value >= 3.0,
    do: %{label: "Dangerous", badge_class: "badge-error", bar_class: "bg-error"}

  defp ammonia_status(value) when value >= 1.5,
    do: %{label: "Building up", badge_class: "badge-warning", bar_class: "bg-warning"}

  defp ammonia_status(_value),
    do: %{label: "Safe", badge_class: "badge-success", bar_class: "bg-success"}

  defp oxygen_status(value) when value < 3.5,
    do: %{label: "Too low", badge_class: "badge-error", bar_class: "bg-error"}

  defp oxygen_status(value) when value < 5.0,
    do: %{label: "Needs more air", badge_class: "badge-warning", bar_class: "bg-warning"}

  defp oxygen_status(_value),
    do: %{label: "Comfortable", badge_class: "badge-success", bar_class: "bg-success"}

  defp gauge_percent(value, maximum) do
    value
    |> Kernel./(maximum)
    |> Kernel.*(100)
    |> max(0.0)
    |> min(100.0)
    |> Float.round(1)
  end

  defp number(map, key) do
    case Map.get(map, key, 0) do
      value when is_integer(value) -> value * 1.0
      value when is_float(value) -> value
      _other -> 0.0
    end
  end

  defp rounded(value) when is_float(value), do: Float.round(value, 2)
end
