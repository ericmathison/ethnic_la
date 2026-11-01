class Admin < ApplicationRecord
  devise :database_authenticatable, :lockable, :rememberable, :trackable, :validatable
end
