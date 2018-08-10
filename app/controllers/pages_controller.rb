class PagesController < ApplicationController
  def attributions
    @attributions = YAML.load_file('config/attributions.yml')
  end
end
