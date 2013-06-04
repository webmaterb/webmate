class ParentTemplate < Webmate::BaseTemplate
  field :name, type: :string
  field :description, type: :text

  embedded_template :child_template
end

class ChildTemplate < Webmate::BaseTemplate
  field :name, type: :string
  field :estimation, type: :integer
  field :due, type: :date
end
