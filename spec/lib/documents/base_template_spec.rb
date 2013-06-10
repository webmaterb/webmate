require 'spec_helper'

class ExampleTemplate < Webmate::BaseTemplate
  field :title, type: :string
end

describe Webmate::BaseTemplate do
  context "initialization" do
    let(:template)  { ExampleTemplate.new() }
    let(:fields)    { double('fields') }
    let(:field)     { double('field') }

    it "should be able to set fields" do
      template.fields = fields
      template.attributes.should eq({'fields' => fields})
    end

    it "should be able to init with fields" do
      template = ExampleTemplate.new(fields: { name: field })
      template.fields['name'].should eq(field)
      template.fields['title'].should_not be_blank
    end

    it "should build only fields" do
      template = ExampleTemplate.new()
      template.attributes['fields']['title'].should_not be_blank
      template.attributes['fields'].keys.should == ['title']
    end

    it "should store attributes" do
      field_value = double('field')
      template = Webmate::BaseTemplate.new(fields: {field_name: field_value})
      template.attributes['fields']['field_name'].should eq(field_value)
    end

    it "should set system fields" do
      field_value = double('field')
      template = ExampleTemplate.new(fields: {field_name: field_value})
      template.attributes['fields']['field_name'].should eq(field_value)
      template.attributes['fields']['title'].should_not be_blank
    end
  end
end
