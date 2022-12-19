defmodule SearchExampleWeb.SearchLive do
  use SearchExampleWeb, :live_view

  alias SearchExample.Skills
  alias SearchExample.Skills.Skill
  alias SearchExample.Search
  alias SearchExample.SearchRule

  def render(assigns) do
    ~H"""

    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_rule: nil)
      |> assign(rules: [])
      |> assign(results: [])

    {:ok, socket}
  end

  def handle_params(%{"r" => rules}, _, socket) do
    rules = map_params_to_rules(rules)
    results = Search.search_users_based_on_rules(rules)

    socket =
      socket
      |> assign(active_rule: nil)
      |> assign(rules: rules)
      |> assign(results: results)

    {:noreply, socket}
  end

  def handle_params(_params, _, socket) do
    {:noreply, socket}
  end

  def handle_event("add_skill", %{"skill_id" => skill_id}, socket) do
    skill = Skills.get_skill(skill_id)

    active_rule = %SearchRule{
      id: Enum.random(1_000..9_999),
      skill: skill,
      type: nil,
      value: nil
    }

    socket = assign(socket, active_rule: active_rule)

    {:noreply, socket}
  end

  def handle_event("set-selected-filter", %{"filter-id" => filter_id}, socket) do
    type = map_filter_id(filter_id)
    active_rule = %{socket.assigns.active_rule | type: type}
    {:noreply, socket |> assign(:active_rule, active_rule)}
  end

  def handle_event("remove-active-rule", _, socket) do
    {:noreply, socket |> assign(:active_rule, nil)}
  end

  def handle_event("remove-rule", %{"id" => id}, socket) do
    rules = Enum.filter(socket.assigns.rules, &(&1.id != id))

    results = Search.search_users_based_on_rules(rules)

    rules_to_encode = alter_rules_for_encode(rules)

    socket = socket |> assign(rules: rules, results: results)

    params = %{r: rules_to_encode}

    {:noreply,
     push_patch(socket,
       to: Routes.live_path(socket, SearchExampleWeb.SearchLive, params),
       replace: true
     )}
  end

  def handle_event("set-skill-rating", %{"rating" => rating}, socket) do
    active_rule = %{socket.assigns.active_rule | value: rating}
    {:noreply, socket |> assign(:active_rule, active_rule)}
  end

  def handle_event("add-rule", _, socket) do
    rules = socket.assigns.rules ++ [socket.assigns.active_rule]

    results = Search.search_users_based_on_rules(rules)

    rules_to_encode = alter_rules_for_encode(rules)

    socket =
      socket
      |> assign(rules: rules, active_rule: nil, results: results)

    params = %{r: rules_to_encode}

    {:noreply,
     push_patch(socket,
       to: Routes.live_path(socket, SearchExampleWeb.SearchLive, params),
       replace: true
     )}
  end

  defp string_to_number(s) do
    case Integer.parse(s) do
      {_, ""} -> String.to_integer(s)
      {_, _reminder} -> String.to_float(s)
      :error -> nil
    end
  end

  defp alter_rules_for_encode(rules) do
    Enum.group_by(rules, & &1.id)
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      value = hd(value)

      rule = %{
        s: %{id: value.skill.id, n: value.skill.name},
        t: value.type,
        v: value.value
      }

      Map.put(acc, key, rule)
    end)
  end

  defp map_filter_id(filter_id) do
    case filter_id do
      1 -> :max
      2 -> :min
      3 -> :is_interested_in
    end
  end

  defp map_params_to_rules(rules) do
    Enum.map(rules, fn {id, value} ->
      %SearchRule{
        id: id,
        skill: %Skill{id: value["s"]["id"], name: value["s"]["n"]},
        type:
          case value["t"] do
            "max" -> :max
            "min" -> :min
            "is_interested_in" -> :is_interested_in
            "" -> nil
          end,
        value: string_to_number(value["v"])
      }
    end)
  end
end
