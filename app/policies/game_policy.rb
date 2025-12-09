class GamePolicy < ApplicationPolicy
  # Public can view games
  def index?
    true
  end

  def show?
    true
  end

  # Only admins can create/update/delete games
  def create?
    user&.admin?
  end

  def update?
    user&.admin?
  end

  def destroy?
    user&.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # All users can see all games
      scope.all
    end
  end
end
