# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Critic::Controller' do
  before { Table.all.clear }

  let!(:user)       { User.new('steve') }
  let!(:controller) { TableController.new(user) }

  Table = Struct.new(:id)

  def Table.all
    @all ||= []
  end

  User = Struct.new(:name)

  class TablePolicy
    include Critic::Policy

    def show
      !subject.name.empty?
    end

    def update
      true
    end

    def index
      Table.all.select { |t| !t.id.to_s.match(/reject/) }
    end
  end

  class TableController
    include Critic::Controller

    def initialize(user)
      @user = user
    end

    def show
      authorize table, :show

      table
    end

    def update
      # looks like a rails controller action
      params[:action] = :update

      table.id = 2
      authorize table

      table
    end

    def index
      authorize_scope Table
    end

    protected

    def table
      @table ||= Table.new(1)
    end

    def params
      @params ||= {}
    end

    def critic
      @user
    end
  end

  describe 'Rails' do
    it 'authorizes a single resource using contextual parameters' do
      expect(controller.update).to eq(Table.new(2))
    end
  end

  it 'authorizes a single resource' do
    expect(controller.show).to eq(Table.new(1))
  end

  it 'authorizes resource scope' do
    [Table.new('1'), Table.new('reject'), Table.new('A')].each { |t| Table.all << t }

    expect(controller.index).to contain_exactly(Table.new('1'), Table.new('A'))
  end
end
