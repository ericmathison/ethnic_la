class LanguagesController < ApplicationController
  def show
    @language = Language.find_by(id: params[:id])
    @ethnic_churches = @language.ethnic_churches.page(params[:page])
  end
end
