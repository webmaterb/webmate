require 'spec_helper'
require 'lib/documents/examples.rb'

describe Webmate::Documents::Templates do
  context "fields management" do
    let(:template) { ParentTemplate.new }
    let(:field_options) { double("field options") }

    it "should be able to add field" do
      field_options = { 'system' => false }
      template.add_field(:my_field, field_options)
      template.fields[:my_field].should eq(field_options)
    end

    it "should not rewrite existing fields" do
      lambda {
        template.add_field('name', field_options)
      }.should raise_error
    end

    it "should be able to remove custom field" do
      field_options = { 'system' => false }
      # add field
      template.add_field(:my_field, field_options)

      template.remove_field(:my_field)
      template.fields[:my_field].should be_blank
    end

    it "should hide system field" do
      template.remove_field(:name)
      template.fields[:name].should_not be_blank
      template.fields[:name][:hide].should be_true
    end
  end
end
