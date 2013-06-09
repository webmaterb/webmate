require 'spec_helper'
require 'lib/documents/examples.rb'

describe Webmate::Documents::Templates do
  context "fields" do
    it "should assign default fields" do
      obj = ParentTemplate.new
      obj.fields[:name].should_not be_blank
      obj.fields[:description].should_not be_blank
    end

    it "should assign any fields" do
      obj = ParentTemplate.new(fields: { birth_date: { type: :date, system: false }})
      obj.fields[:birth_date].should_not be_blank
    end
  end

  context "embedded_templates" do
    it "should provide access to embedded templates" do
      parent_template = ParentTemplate.new()
      parent_template.child_template.fields[:name].should_not be_blank
    end
  end
end
