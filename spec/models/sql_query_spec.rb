require 'spec_helper'

module InstrumentAllTheThings
  describe SQLQuery do
    describe ".parse_query" do

      it "handls gibberish" do
        expect(SQLQuery.parse_query("asfasdf")).to eq(table: 'unknown', action: 'unknown')
      end

      it "handles a basic select" do
        expect(SQLQuery.parse_query(%Q{SELECT * FROM foobar})).to eq(table: 'foobar', action: 'select')
      end

      it "handles a quoted select" do
        expect(SQLQuery.parse_query(%Q{SELECT * FROM "foobar"})).to eq(table: 'foobar', action: 'select')
      end

      it "handles a select with specific fields" do
        expect(SQLQuery.parse_query(%Q{SELECT hrm,fd,sdf FROM "foobar"})).to eq(table: 'foobar', action: 'select')
      end

      it "identifes a count select" do
        expect(SQLQuery.parse_query(%Q{SELECT count(*) FROM "foobar"})).to eq(table: 'foobar', action: 'count')
      end

      it "identifes a specific count" do
        expect(SQLQuery.parse_query(%Q{SELECT count(fo.jk) FROM "foobar"})).to eq(table: 'foobar', action: 'count')
      end

      it "identfies an update" do
        expect(SQLQuery.parse_query(%Q{UPDATE foobar SET foo = 'bar'})).to eq(table: 'foobar', action: 'update')
      end

      it "identfies a quoted update" do
        expect(SQLQuery.parse_query(%Q{UPDATE "foobar" SET foo = 'bar'})).to eq(table: 'foobar', action: 'update')
      end

      it "identfies an unquoted destroy" do
        expect(SQLQuery.parse_query(%Q{DELETE FROM foobar WHERE foo = 'bar'})).to eq(table: 'foobar', action: 'delete')
      end

      it "identfies an quoted destroy" do
        expect(SQLQuery.parse_query(%Q{DELETE FROM "foobar" WHERE foo = 'bar'})).to eq(table: 'foobar', action: 'delete')
      end
    end
  end
end
