class Developer < ApplicationRecord
  # Associations
  has_many :games, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :website_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

  # Callbacks
  before_validation :generate_slug, if: -> { name.present? && slug.blank? }

  # Scopes
  scope :alphabetical, -> { order(:name) }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
