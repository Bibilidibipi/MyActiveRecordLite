require '04_associatable2'
require 'byebug'

describe 'Associatable' do
  before(:each) { DBConnection.reset }
  after(:each) { DBConnection.reset }

  before(:all) do
    class Cat < SQLObject
      belongs_to :human, foreign_key: :owner_id

      finalize!
    end

    class Human < SQLObject
      self.table_name = 'humans'

      has_many :cats, foreign_key: :owner_id
      belongs_to :house

      finalize!
    end

    class House < SQLObject
      has_many :humans

      finalize!
    end
  end

  describe '::assoc_options' do
    it 'defaults to empty hash' do
      class TempClass < SQLObject
      end

      expect(TempClass.assoc_options).to eq({})
    end

    it 'stores `belongs_to` options' do
      cat_assoc_options = Cat.assoc_options
      human_options = cat_assoc_options[:human]

      expect(human_options).to be_instance_of(BelongsToOptions)
      expect(human_options.foreign_key).to eq(:owner_id)
      expect(human_options.class_name).to eq('Human')
      expect(human_options.primary_key).to eq(:id)
    end

    it 'stores options separately for each class' do
      expect(Cat.assoc_options).to have_key(:human)
      expect(Human.assoc_options).to_not have_key(:human)

      expect(Human.assoc_options).to have_key(:house)
      expect(Cat.assoc_options).to_not have_key(:house)
    end
  end

  describe '#has_one_through' do
    before(:all) do
      class Cat
        has_one_through :home, :human, :house

        self.finalize!
      end
    end

    let(:cat) { Cat.find(1) }

    it 'adds getter method' do
      expect(cat).to respond_to(:home)
    end

    it 'fetches associated `home` for a `Cat`' do
      house = cat.home

      expect(house).to be_instance_of(House)
      expect(house.address).to eq('26th and Guerrero')
    end
  end

  describe '#has_many_through' do
    before(:all) do
      class House
        has_many_through :cats, :humans, :cats
        has_many_through :countries, :humans, :country

        self.finalize!
      end

      class Country < SQLObject
        has_many :humans
        has_many :trees

        finalize!
      end

      class Human
        belongs_to :country
        has_many_through :trees, :country, :trees

        self.finalize!
      end

      class Tree <SQLObject
        belongs_to :country

        finalize!
      end
    end

    let(:house) { House.find(1) }
    let(:human) { Human.find(1) }

    it 'adds getter method for has_many => has_many' do
      expect(house).to respond_to(:cats)
    end

    it 'fetches associated `cats` for a `House`' do
      cats = house.cats

      expect(cats.first).to be_instance_of(Cat)
      expect(cats.first.name).to eq('Breakfast')
    end

    it 'adds getter method for has_many => belongs_to' do
      expect(house).to respond_to(:countries)
    end

    it 'fetches associated `countries` for a `House`' do
      countries = house.countries

      expect(countries.first).to be_instance_of(Country)
      expect(countries.first.name).to eq('France')
    end

    it 'adds getter method for belongs_to => has_many' do
      expect(human).to respond_to(:trees)
    end

    it 'fetches associated `trees` for a `Human`' do
      trees = human.trees

      expect(trees.first).to be_instance_of(Tree)
      expect(trees.first.name).to eq('Eggbert')
    end
  end
end
