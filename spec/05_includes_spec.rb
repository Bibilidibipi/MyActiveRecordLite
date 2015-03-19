require 'byebug'
require '03_associatable'
require 'db-query-matchers'

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
  end

  describe '#includes' do
    it "doesn't repeat a db query" do
      h = Human.includes(:cats).first

      expect{h.cats}.to_not make_database_queries
    end
  end
end
