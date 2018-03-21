class LanguagesController < ApplicationController
  def show
    @language = Language.where(id: params[:id]).first
    @ethnic_churches = @language.ethnic_churches
    @languages = Language.list
  end
end
