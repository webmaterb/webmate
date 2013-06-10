require 'spec_helper'

describe Webmate::Documents::MongoDocument do
  context "attributes" do
    it "should return empty hash by default" do
      doc = Webmate::Documents::MongoDocument.new
      doc.attributes.should be_kind_of(Hash)
      doc.attributes.should be_blank
    end

    it "should store attributes" do
      attrs_mock = double('hash attrs')
      attrs_mock.stub(:select).and_return(attrs_mock)
      doc = Webmate::Documents::MongoDocument.new(attrs_mock)
      doc.attributes.should eq(attrs_mock)
    end

    it "should allows to update attributes" do
      doc = Webmate::Documents::MongoDocument.new
      fields_mock = double('fields attrs')
      doc.attributes[:fields] = fields_mock
      doc.attributes.should eq({fields: fields_mock})
    end
  end

  context "save" do
    let(:collection) { double('collection') }

    it "should assign id if not exists" do
      Webmate::Documents::MongoDocument.stub!(:collection).and_return(collection)
      collection.should_receive(:insert).and_return(true)

      doc = Webmate::Documents::MongoDocument.new
      doc.save

      doc.id.should_not be_blank
    end

    it "should store existed attributes"
    it "should store given attributes"
  end
end

