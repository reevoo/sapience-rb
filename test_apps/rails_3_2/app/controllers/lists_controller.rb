# frozen_string_literal: true
class ListsController < ApplicationController
  def index
    @lists = List.all
  end

  def show
    @list = List.find(params[:id])
  end

  def new
    @list = List.new
  end

  def create
    @list = List.create(params[:list])
  end

  def edit
    @list = List.find(params[:id])
  end

  def update
    @list = List.find(params[:id])
    @list.update(params[:list])
  end

  def destroy
    @list = List.find(params[:id])
    @list.destroy
  end
end
