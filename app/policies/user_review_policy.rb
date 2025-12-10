class UserReviewPolicy < ApplicationPolicy
  # Anyone can view approved reviews
  def index?
    true
  end

  def show?
    # Approved reviews visible to all
    # Pending/flagged reviews visible to owner or moderators
    record.approved? || owner? || user&.moderator_or_admin?
  end

  # Authenticated users can create reviews
  def create?
    user.present?
  end

  # Users can edit their own pending reviews
  def update?
    owner? && record.pending?
  end

  # Users can delete their own reviews
  def destroy?
    owner?
  end

  # Moderation actions for moderators/admins
  def approve?
    user&.moderator_or_admin?
  end

  def flag?
    user&.moderator_or_admin?
  end

  def reject?
    user&.moderator_or_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.moderator_or_admin?
        # Moderators/admins see all reviews
        scope.all
      elsif user
        # Authenticated users see approved reviews + their own
        scope.where(moderation_status: :approved).or(scope.where(user_id: user.id))
      else
        # Public sees only approved reviews
        scope.approved
      end
    end
  end

  private

  def owner?
    user && record.user_id == user.id
  end
end
