require 'spec_helper'

def convert_to_json_and_back(resources, presenter_class)
  json = presenter_class.new(resources).to_json
  JSON.parse(json)
end

def build_presenter_class(&definition)
  result = Class.new(Webmate::BasePresenter) do
    @attributes_definition_block = definition

    def to_serializable
      definition = self.class.instance_eval { @attributes_definition_block }
      build_serialized default_resource do |resource|
        self.instance_exec resource, &definition
      end
    end
  end

  result
end

simple_presenter_class  = Class.new(Webmate::BasePresenter)
test_model_class = Class.new do
  def initialize(args = {})
    @attributes = args.symbolize_keys!
  end

  def attributes
    @attributes
  end

  def method_missing(name, *args)
    if @attributes.keys.include?(name.to_sym)
      @attributes[name.to_sym]
    else
      super
    end
  end
end

describe "serialize to json" do
  let(:model) { test_model_class.new(login: 'login', name: 'name') }
  it 'should serialize as single record' do
    result = convert_to_json_and_back(model, simple_presenter_class)
    result.should be_a_kind_of(Hash)
  end

  it 'should serialize to array' do
    models = Array.new(2) do |i|
      test_model_class.new(login: "login-#{i}", name: "name-#{i}")
    end
    result = convert_to_json_and_back(models, simple_presenter_class)
    result.should be_a_kind_of(Array)
  end

  it "should serialize all attributes by default" do
    result = convert_to_json_and_back(model, simple_presenter_class)
    result.keys.should eq(%w{login name})
  end

  it "should use defined in 'attributes'" do
    presenter_class  = build_presenter_class do |resource|
      attributes :login, :name
    end
    model = test_model_class.new(login: 'login', name: 'name', another: 'another')
    result = convert_to_json_and_back(model, presenter_class)
    result.keys.should eq(%w{login name})
  end

  it "should use block attribute" do
    presenter_class = build_presenter_class do |resource|
      attribute :custom_field_attributes do
        resource.attributes # - by some way, this will be [] instead {}. 
      end
    end
    model = test_model_class.new({ code: 'mode' })
    result = convert_to_json_and_back(model, presenter_class)

    result['custom_field_attributes'].should eq(model.attributes.stringify_keys)
  end
end
