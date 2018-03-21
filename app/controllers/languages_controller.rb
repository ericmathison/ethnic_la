class LanguagesController < ApplicationController
  def show
    @language = Language.where(id: params[:id]).first
    @ethnic_churches = EthnicChurch.joins(:language).where(Language.arel_table[:id].eq(@language.id))
    @languages = Language.list
  end
end
