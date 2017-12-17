class EthnicChurchesController < ApplicationController
  def index
    @ethnic_churches = EthnicChurch.all
  end
end
