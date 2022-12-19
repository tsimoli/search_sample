defmodule SearchExample.Search do
  import Ecto.Query

  alias SearchExample.Repo
  alias SearchExample.Skills.Skill
  alias SearchExample.SearchRule
  alias SearchExample.Accounts.User

  def search_users_based_on_rules([]) do
    []
  end

  def search_users_based_on_rules(rules) do
    base_query = from(u in User)

    query = apply_rules_to_query(base_query, rules)

    Repo.all(query)
    |> Repo.preload([:org_role, skills: [:skill], interested_in_skills: [:skill]])
  end

  defp apply_rules_to_query(base_query, rules) do
    Enum.reduce(rules, base_query, fn
      %SearchRule{skill: %Skill{} = skill, type: :is_interested_in, value: nil}, query ->
        from(u in query,
          join: uiis in UserInterestedInSkill,
          on: u.id == uiis.user_id,
          where: uiis.skill_id == ^skill.id
        )

      %SearchRule{skill: %Skill{} = skill, type: nil, value: _}, query ->
        from(u in query,
          join: us in UserSkill,
          on: u.id == us.user_id,
          where: us.skill_id == ^skill.id
        )

      %SearchRule{skill: %Skill{} = skill, type: :max, value: value}, query ->
        from(u in query,
          join: us in UserSkill,
          on: u.id == us.user_id,
          where: us.skill_id == ^skill.id and us.rating < ^value
        )

      %SearchRule{skill: %Skill{} = skill, type: :min, value: value}, query ->
        from(u in query,
          join: us in UserSkill,
          on: u.id == us.user_id,
          where: us.skill_id == ^skill.id and us.rating > ^value
        )

      %SearchRule{skill: %Skill{} = skill, type: _, value: nil}, query ->
        from(u in query,
          join: us in UserSkill,
          on: u.id == us.user_id,
          where: us.skill_id == ^skill.id
        )
    end)
  end
end
