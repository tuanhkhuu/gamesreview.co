class Publication < ApplicationRecord
  # Associations
  has_many :critic_reviews, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :website_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
  validates :credibility_weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10, allow_nil: true }

  # Callbacks
  before_validation :generate_slug, if: -> { name.present? && slug.blank? }

  # Scopes
  scope :alphabetical, -> { order(:name) }
  scope :by_credibility, -> { order(credibility_weight: :desc) }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
